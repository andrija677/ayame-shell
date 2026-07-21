#!/usr/bin/env bash
set -euo pipefail

prefix="${XDG_DATA_HOME:-$HOME/.local/share}/ayame-shell"
assume_yes=false
for argument in "$@"; do
    case "$argument" in
        --yes) assume_yes=true ;;
        --prefix=*) prefix="${argument#*=}" ;;
        *) echo "Unknown option: $argument" >&2; exit 2 ;;
    esac
done

bin_path="${XDG_BIN_HOME:-$HOME/.local/bin}/ayame-shell"
hypr_main="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.lua"
hypr_fragment="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/ayame-shell.lua"
kitty_main="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf"
kitty_fragment="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/ayame-shell.conf"
sudoers_file="/etc/sudoers.d/ayame-hyprshutdown-${USER}"
shell_service="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/ayame-shell.service"

echo "This removes Ayame's installed files and generated Hyprland Lua loader."
if [[ "$assume_yes" != true ]]; then
    read -r -p "Continue? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 0
fi

if [[ -x "$prefix/scripts/ayame-session-takeover.sh" ]]; then
    "$prefix/scripts/ayame-session-takeover.sh" restore
fi

systemctl --user disable --now ayame-shell.service >/dev/null 2>&1 || true
rm -f "$shell_service"
systemctl --user daemon-reload

if [[ -f "$hypr_main" ]]; then
    temporary="$(mktemp)"
    awk -v fragment="$hypr_fragment" \
        '$0 != "-- Created by Ayame Shell for a new Hyprland profile." &&
         $0 != "-- Ayame Shell" && $0 != "dofile(\"" fragment "\")"' \
        "$hypr_main" > "$temporary"
    cp -a "$hypr_main" "$hypr_main.ayame-uninstall-backup-$(date +%Y%m%d-%H%M%S)"
    if grep -q '[^[:space:]]' "$temporary"; then
        install -m 0644 "$temporary" "$hypr_main"
    else
        rm -f "$hypr_main"
    fi
    rm -f "$temporary"
fi

if [[ -f "$kitty_main" ]]; then
    temporary="$(mktemp)"
    awk -v fragment="$kitty_fragment" \
        '$0 != "# Created by Ayame Shell." &&
         $0 != "# Ayame Shell" && $0 != "include " fragment' \
        "$kitty_main" > "$temporary"
    if grep -q '[^[:space:]]' "$temporary"; then
        install -m 0644 "$temporary" "$kitty_main"
    else
        rm -f "$kitty_main"
    fi
    rm -f "$temporary"
fi

rm -f "$bin_path" "$hypr_fragment" "$kitty_fragment" \
    "${XDG_CONFIG_HOME:-$HOME/.config}/kitty/ayame-colors.conf"
rm -rf -- "$prefix"
if [[ -f "$sudoers_file" ]] \
        && sudo grep -Eq "^${USER} ALL=\\(root\\) NOPASSWD: /usr/bin/chvt [0-9]+$" "$sudoers_file"; then
    sudo rm -f "$sudoers_file"
fi
echo "Ayame Shell was removed. Existing pre-install backups were left untouched."
