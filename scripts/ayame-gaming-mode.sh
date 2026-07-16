#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ayame-shell"
marker="$state_dir/gaming-mode"
mkdir -p "$state_dir"

apply_mode() {
    local enabled="$1"
    if [[ "$enabled" == true ]]; then
        hyprctl eval \
            'hl.config({animations={enabled=false},decoration={rounding=0,blur={enabled=false},shadow={enabled=false}}})' \
            >/dev/null
        touch "$marker"
    else
        hyprctl eval \
            'hl.config({animations={enabled=true},decoration={rounding=14,blur={enabled=true},shadow={enabled=true}}})' \
            >/dev/null
        rm -f "$marker"
    fi
}

case "${1:-toggle}" in
    status)
        [[ -f "$marker" ]] && printf '1\n' || printf '0\n'
        ;;
    on)
        apply_mode true
        ;;
    off)
        apply_mode false
        ;;
    toggle)
        if [[ -f "$marker" ]]; then
            apply_mode false
        else
            apply_mode true
        fi
        ;;
    *)
        echo "Usage: ${0##*/} {status|on|off|toggle}" >&2
        exit 2
        ;;
esac
