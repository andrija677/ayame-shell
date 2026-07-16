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

background_hex=${background#\#}
red=$((16#${background_hex:0:2}))
green=$((16#${background_hex:2:2}))
blue=$((16#${background_hex:4:2}))
if ((299 * red + 587 * green + 114 * blue > 128000)); then
    appearance_mode=light
else
    appearance_mode=dark
fi

palette_query="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/ayame-palette-query.py"
if command -v python3 >/dev/null 2>&1 && [[ -f "$palette_query" ]]; then
    mapfile -t dynamic < <(python3 "$palette_query" "$appearance_mode" || true)
    if ((${#dynamic[@]} == 6)); then
        background=${dynamic[0]}
        foreground=${dynamic[1]}
        primary=${dynamic[2]}
        on_primary=${dynamic[3]}
        surface_high=${dynamic[4]}
        outline=${dynamic[5]}
        surface=$background
    fi
fi

theme=$(mktemp --tmpdir ayame-emoji.XXXXXX.rasi)
trap 'rm -f -- "$theme"' EXIT
sed \
    -e "s/@BACKGROUND@/${background}FA/g" \
    -e "s/@FOREGROUND@/$foreground/g" \
    -e "s/@PRIMARY@/$primary/g" \
    -e "s/@ON_PRIMARY@/$on_primary/g" \
    -e "s/@SURFACE@/${surface}E8/g" \
    -e "s/@SURFACE_HIGH@/${surface_high}F5/g" \
    -e "s/@OUTLINE@/$outline/g" \
    "$template" > "$theme"

exec rofimoji --selector rofi --action copy --clipboarder wl-copy \
    --prompt "Emoji" --selector-args "-no-config -theme $theme"
