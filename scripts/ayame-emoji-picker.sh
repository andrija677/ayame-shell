#!/usr/bin/env bash
set -euo pipefail

if ! command -v rofimoji >/dev/null 2>&1; then
    notify-send "Ayame Emoji Picker" "rofimoji is not installed" 2>/dev/null || true
    exit 1
fi

exec rofimoji --selector rofi --action copy --clipboarder wl-copy \
    --prompt "Emoji"
