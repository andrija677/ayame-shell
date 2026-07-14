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

"$temporary_dir/source/install.sh" "$@"
