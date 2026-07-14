#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ayame-shell"
wallpaper_file="$state_dir/wallpaper.path"
hyprpaper_config="$state_dir/hyprpaper.conf"

write_config() {
    local wallpaper="$1"
    local temporary="$hyprpaper_config.tmp"

    cat > "$temporary" <<EOF
splash = false
ipc = true

wallpaper {
    monitor =
    path = $wallpaper
    fit_mode = cover
}
EOF
    mv -f "$temporary" "$hyprpaper_config"
}

mkdir -p "$state_dir"

case "${1:-}" in
    start)
        if [[ -r "$wallpaper_file" ]]; then
            IFS= read -r wallpaper < "$wallpaper_file" || true
            if [[ -n "${wallpaper:-}" && -f "$wallpaper" ]]; then
                write_config "$wallpaper"
                exec hyprpaper --config "$hyprpaper_config"
            fi
        fi
        printf 'splash = false\nipc = true\n' > "$hyprpaper_config"
        exec hyprpaper --config "$hyprpaper_config"
        ;;
    set)
        wallpaper="${2:-}"
        [[ -f "$wallpaper" ]] || {
            echo "Wallpaper does not exist: $wallpaper" >&2
            exit 1
        }
        wallpaper="$(readlink -f -- "$wallpaper")"
        [[ "$wallpaper" != *$'\n'* ]] || {
            echo "Wallpaper paths cannot contain newlines" >&2
            exit 1
        }
        printf '%s\n' "$wallpaper" > "$wallpaper_file.tmp"
        mv -f "$wallpaper_file.tmp" "$wallpaper_file"
        write_config "$wallpaper"
        hyprctl hyprpaper wallpaper ", $wallpaper, cover"
        ;;
    *)
        echo "Usage: ${0##*/} {start|set PATH}" >&2
        exit 2
        ;;
esac
