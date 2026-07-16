#!/usr/bin/env bash
set -euo pipefail

if ! command -v rofimoji >/dev/null 2>&1; then
    notify-send "Ayame Emoji Picker" "rofimoji is not installed" 2>/dev/null || true
    exit 1
fi

palette="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/ayame-colors.conf"
template="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/config/rofi/ayame-emoji.rasi"

palette_color() {
    local name=$1 fallback=$2 value=""
    if [[ -f "$palette" ]]; then
        value=$(awk -v property="$name" '$1 == property { print $2; exit }' "$palette")
    fi
    if [[ "$value" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
        printf '%s' "$value"
    else
        printf '%s' "$fallback"
    fi
}

background=$(palette_color background '#121116')
foreground=$(palette_color foreground '#F0ECF4')
primary=$(palette_color cursor '#D0BCFF')
on_primary=$(palette_color cursor_text_color '#381E72')
surface=$background
surface_high=$(palette_color inactive_tab_background '#302D39')
outline=$(palette_color color8 '#958E9B')

theme=$(mktemp --tmpdir ayame-emoji.XXXXXX.rasi)
trap 'rm -f -- "$theme"' EXIT
sed \
    -e "s/@BACKGROUND@/${background}F2/g" \
    -e "s/@FOREGROUND@/$foreground/g" \
    -e "s/@PRIMARY@/$primary/g" \
    -e "s/@ON_PRIMARY@/$on_primary/g" \
    -e "s/@SURFACE@/${surface}B8/g" \
    -e "s/@SURFACE_HIGH@/${surface_high}F0/g" \
    -e "s/@OUTLINE@/$outline/g" \
    "$template" > "$theme"

exec rofimoji --selector rofi --action copy --clipboarder wl-copy \
    --prompt "Emoji" --selector-args "-no-config -theme $theme"
