#!/usr/bin/env bash
set -euo pipefail

prefix="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
vt=3
if [[ -r "$prefix/sddm-vt" ]]; then
    IFS= read -r configured_vt < "$prefix/sddm-vt" || true
    [[ "${configured_vt:-}" =~ ^[0-9]+$ ]] && vt="$configured_vt"
fi

session_id="${XDG_SESSION_ID:-}"
if [[ -z "$session_id" ]] && command -v loginctl >/dev/null 2>&1; then
    session_id="$(loginctl show-user "$USER" -p Display --value 2>/dev/null || true)"
fi

arguments=(--vt "$vt" --top-label "Logging out of Ayame…")
if [[ -n "$session_id" ]]; then
    printf -v post_command 'loginctl terminate-session %q' "$session_id"
    arguments+=(--post-cmd "$post_command")
fi

exec hyprshutdown "${arguments[@]}"
