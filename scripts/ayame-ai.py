#!/usr/bin/env python3
"""Small streaming AI bridge for Ayame Shell.

Secrets live in Secret Service. Chat requests and responses use JSON lines on
stdin/stdout so prompts never appear in the process list.
"""

import json
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request


def emit(kind: str, **values: object) -> None:
    print(json.dumps({"type": kind, **values}, ensure_ascii=False), flush=True)


def start_secret_service() -> bool:
    candidates = [
        ["ksecretd"],
        ["gnome-keyring-daemon", "--start", "--components=secrets"],
    ]
    for command in candidates:
        try:
            subprocess.Popen(
                command,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
            time.sleep(0.8)
            return True
        except FileNotFoundError:
            continue
    return False


def run_secret_tool(arguments: list[str], input_text: str | None = None) -> subprocess.CompletedProcess:
    result = subprocess.run(
        ["secret-tool", *arguments],
        input=input_text, check=False, capture_output=True, text=True,
    )
    if result.returncode != 0 and "not activatable" in result.stderr.lower():
        if start_secret_service():
            result = subprocess.run(
                ["secret-tool", *arguments],
                input=input_text, check=False, capture_output=True, text=True,
            )
    return result


def secret(provider: str) -> str:
    if not shutil.which("secret-tool"):
        return ""
    result = run_secret_tool(
        ["lookup", "service", "ayame-shell-ai", "provider", provider])
    return result.stdout.strip() if result.returncode == 0 else ""


def store_secret(provider: str, value: str) -> int:
    if not value:
        return 2
    if not shutil.which("secret-tool"):
        print("Install libsecret (Arch) or libsecret-tools (Debian/Ubuntu) "
              "to store API keys securely", file=sys.stderr)
        return 127
    result = run_secret_tool(
        [
            "store", "--label",
            f"Ayame AI ({provider})", "service", "ayame-shell-ai",
            "provider", provider,
        ],
        value,
    )
    if result.returncode != 0:
        print(result.stderr.strip()
              or "No compatible Secret Service keyring is available", file=sys.stderr)
    return result.returncode


def delete_secret(provider: str) -> int:
    if not shutil.which("secret-tool"):
        print("secret-tool is not installed", file=sys.stderr)
        return 127
    result = run_secret_tool(
        ["clear", "service", "ayame-shell-ai", "provider", provider])
    if result.returncode != 0:
        print(result.stderr.strip(), file=sys.stderr)
    return result.returncode


def request(url: str, headers: dict[str, str], body: dict) -> urllib.response.addinfourl:
    data = json.dumps(body, ensure_ascii=False).encode()
    return urllib.request.urlopen(
        urllib.request.Request(url, data=data, headers=headers, method="POST"),
        timeout=90,
    )


def openai_stream(config: dict, messages: list[dict]) -> None:
    key = secret("openai")
    if not key:
        raise RuntimeError("Add an OpenAI-compatible API key in Ayame Settings")
    base = config.get("baseUrl", "https://api.openai.com").rstrip("/")
    body = {"model": config.get("model") or "gpt-4.1-mini",
            "messages": messages, "stream": True}
    with request(base + "/v1/chat/completions",
                 {"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
                 body) as response:
        for raw in response:
            line = raw.decode("utf-8", "replace").strip()
            if not line.startswith("data:"):
                continue
            payload = line[5:].strip()
            if payload == "[DONE]":
                break
            data = json.loads(payload)
            text = data.get("choices", [{}])[0].get("delta", {}).get("content", "")
            if text:
                emit("delta", text=text)


def gemini_stream(config: dict, messages: list[dict]) -> None:
    key = secret("gemini")
    if not key:
        raise RuntimeError("Add a Gemini API key in Ayame Settings")
    model = urllib.parse.quote(config.get("model") or "gemini-2.5-flash", safe="")
    url = (f"https://generativelanguage.googleapis.com/v1beta/models/{model}"
           f":streamGenerateContent?alt=sse&key={urllib.parse.quote(key, safe='')}")
    system = messages[0]["content"]
    contents = []
    for item in messages[1:]:
        contents.append({
            "role": "model" if item["role"] == "assistant" else "user",
            "parts": [{"text": item["content"]}],
        })
    body = {"system_instruction": {"parts": [{"text": system}]}, "contents": contents}
    with request(url, {"Content-Type": "application/json"}, body) as response:
        for raw in response:
            line = raw.decode("utf-8", "replace").strip()
            if not line.startswith("data:"):
                continue
            data = json.loads(line[5:].strip())
            parts = data.get("candidates", [{}])[0].get("content", {}).get("parts", [])
            for part in parts:
                if part.get("text"):
                    emit("delta", text=part["text"])


def ollama_stream(config: dict, messages: list[dict]) -> None:
    base = config.get("baseUrl", "http://127.0.0.1:11434").rstrip("/")
    body = {"model": config.get("model") or "llama3.2",
            "messages": messages, "stream": True}
    with request(base + "/api/chat", {"Content-Type": "application/json"}, body) as response:
        for raw in response:
            if not raw.strip():
                continue
            data = json.loads(raw)
            text = data.get("message", {}).get("content", "")
            if text:
                emit("delta", text=text)
            if data.get("done"):
                break


def chat() -> int:
    config = json.loads(sys.stdin.readline())
    history = config.get("history", [])[-20:]
    messages = [{"role": "system", "content": config["systemPrompt"]}]
    messages.extend({"role": item["role"], "content": item["content"]} for item in history)
    provider = config.get("provider", "gemini")
    try:
        if provider == "gemini":
            gemini_stream(config, messages)
        elif provider == "openai":
            openai_stream(config, messages)
        elif provider == "ollama":
            ollama_stream(config, messages)
        else:
            raise RuntimeError("Unsupported AI provider")
        emit("done")
        return 0
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", "replace")
        try:
            detail = json.loads(detail).get("error", {}).get("message", detail)
        except json.JSONDecodeError:
            pass
        emit("error", message=f"Provider error {error.code}: {detail[:240]}")
    except (urllib.error.URLError, TimeoutError) as error:
        emit("error", message=f"Could not reach the AI provider: {error.reason}")
    except (KeyError, ValueError, RuntimeError) as error:
        emit("error", message=str(error))
    return 1


def main() -> int:
    action = sys.argv[1] if len(sys.argv) > 1 else ""
    provider = sys.argv[2] if len(sys.argv) > 2 else ""
    if action == "chat":
        return chat()
    if action == "key-store":
        return store_secret(provider, sys.stdin.readline().strip())
    if action == "key-delete":
        return delete_secret(provider)
    if action == "key-status":
        print("1" if secret(provider) else "0")
        return 0
    print("Usage: ayame-ai.py {chat|key-store|key-delete|key-status} [provider]",
          file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
