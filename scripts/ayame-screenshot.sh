#!/usr/bin/env bash
set -euo pipefail

mode="${1:-area}"
delay="${2:-0}"
monitor="${3:-}"
directory="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$directory"
output="$directory/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

if [[ "$delay" =~ ^[0-9]+$ ]] && (( delay > 0 )); then
    sleep "$delay"
fi

case "$mode" in
    desktop)
        grim "$output"
        ;;
    monitor)
        if [[ -z "$monitor" || "$monitor" == "AUTO" ]]; then
            monitor="$(hyprctl monitors 2>/dev/null | awk '
                /^Monitor / { current=$2 }
                /^[[:space:]]*focused: yes/ { print current; exit }
            ')"
        fi
        [[ -n "$monitor" ]] || { echo "No monitor was provided" >&2; exit 2; }
        grim -o "$monitor" "$output"
        ;;
    area)
        geometry="$(slurp)" || exit 0
        [[ -n "$geometry" ]] || exit 0
        grim -g "$geometry" "$output"
        ;;
    *)
        echo "Unknown capture mode: $mode" >&2
        exit 2
        ;;
esac

wl-copy --type image/png < "$output"
command -v notify-send >/dev/null && notify-send "Screenshot saved" "$output"
printf '%s\n' "$output"
