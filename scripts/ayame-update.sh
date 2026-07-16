#!/usr/bin/env bash
set -euo pipefail

archive_url="https://github.com/andrija677/ayame-shell/archive/refs/heads/main.tar.gz"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ayame-shell"
install_dir="${XDG_DATA_HOME:-$HOME/.local/share}/ayame-shell"
log_file="$state_dir/update.log"
temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "$temporary_dir"' EXIT
mkdir -p "$state_dir"

printf '[%s] Checking for Ayame Shell updates\n' \
    "$(date --iso-8601=seconds)" >>"$log_file"
curl -fsSL "$archive_url" -o "$temporary_dir/ayame-shell.tar.gz" \
    2>>"$log_file"
mkdir -p "$temporary_dir/source"
tar -xzf "$temporary_dir/ayame-shell.tar.gz" \
    --strip-components=1 -C "$temporary_dir/source" 2>>"$log_file"

update_available=false
for payload in assets config docs scripts themes README.md bootstrap.sh \
        install.sh uninstall.sh; do
    if ! diff -qr "$temporary_dir/source/$payload" "$install_dir/$payload" \
            >/dev/null 2>&1; then
        update_available=true
        break
    fi
done

if [[ "$update_available" != true ]]; then
    printf '[%s] Already up to date\n' "$(date --iso-8601=seconds)" \
        >>"$log_file"
    printf "You're all up to date! :3\n"
    exit 0
fi

{
    printf '[%s] Installing Ayame Shell update\n' "$(date --iso-8601=seconds)"
    "$temporary_dir/source/install.sh" --update
    printf '[%s] Update completed\n' "$(date --iso-8601=seconds)"
} >>"$log_file" 2>&1

notify-send -a "Ayame Shell" "Ayame Shell finished updating! :3" \
    "Please make sure to log off, then log back in!" \
    2>/dev/null || true
printf 'Ayame Shell finished updating! Please make sure to log off, then log back in! :3\n'
