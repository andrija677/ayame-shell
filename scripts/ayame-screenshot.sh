#!/usr/bin/env bash
set -euo pipefail

mode="${1:-area}"
delay="${2:-0}"
monitor="${3:-}"
directory="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$directory"
output="$directory/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
screenshot_icon="$script_dir/../assets/icons/screenshot.svg"
selector_settle_delay="0.20"

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
    geometry)
        geometry="$monitor"
        [[ "$geometry" =~ ^-?[0-9]+,-?[0-9]+[[:space:]][0-9]+x[0-9]+$ ]] || {
            echo "Invalid screenshot geometry: $geometry" >&2
            exit 2
        }
        # Allow the QML selection layer to fully unmap before Grim asks the
        # compositor for the next frame. Without this, its size badge can be
        # retained in the captured buffer on some Hyprland/GPU combinations.
        sleep "$selector_settle_delay"
        grim -g "$geometry" "$output"
        ;;
    area)
        selector_error="$(mktemp)"
        if ! geometry="$(slurp -d -b '#00000099' -c '#c6a0ffff' -s '#6d4c8e66' -w 3 \
                2>"$selector_error")"; then
            error="$(<"$selector_error")"
            rm -f "$selector_error"
            if [[ -n "$error" ]]; then
                echo "$error" >&2
            else
                echo "Area selector exited before a region was chosen" >&2
            fi
            exit 1
        fi
        rm -f "$selector_error"
        [[ -n "$geometry" ]] || {
            echo "Area selector returned an empty region" >&2
            exit 1
        }
        # Slurp has exited, but its final overlay buffer may still be present
        # for one compositor frame.
        sleep "$selector_settle_delay"
        grim -g "$geometry" "$output"
        ;;
    *)
        echo "Unknown capture mode: $mode" >&2
        exit 2
        ;;
esac

wl-copy --type image/png < "$output" 2>/dev/null || true
if command -v notify-send >/dev/null; then
    notify-send -a "Ayame Screenshot" -i "$screenshot_icon" \
        "Screenshot saved" "$output" 2>/dev/null || true
fi
printf '%s\n' "$output"
