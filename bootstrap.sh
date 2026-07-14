#!/usr/bin/env bash
set -euo pipefail

archive_url="https://github.com/andrija677/ayame-shell/archive/refs/heads/main.tar.gz"
temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "$temporary_dir"' EXIT

echo "Downloading Ayame Shell..."
curl -fsSL "$archive_url" -o "$temporary_dir/ayame-shell.tar.gz"
mkdir -p "$temporary_dir/source"
tar -xzf "$temporary_dir/ayame-shell.tar.gz" \
    --strip-components=1 -C "$temporary_dir/source"

# `curl ... | bash` occupies standard input with the bootstrap source. Reopen
# the controlling terminal so the real installer can ask its interactive
# confirmation questions. Non-interactive callers still work with `--yes`.
if { exec 3</dev/tty; } 2>/dev/null; then
    "$temporary_dir/source/install.sh" "$@" <&3
    exec 3<&-
else
    "$temporary_dir/source/install.sh" "$@"
fi
