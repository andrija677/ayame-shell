#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ayame-shell"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/ayame-shell"
mkdir -p "$state_dir" "$runtime_dir"

case "${1:-status}" in
    status)
        if compgen -G '/sys/class/backlight/*' >/dev/null; then
            value="$(brightnessctl -m 2>/dev/null | awk -F, 'NR == 1 { gsub(/%/, "", $4); print $4 }')"
            printf 'brightness|1|%s\n' "${value:-50}"
        else
            printf 'brightness|0|0\n'
        fi
        if brightnessctl --list 2>/dev/null | grep -qiE 'kbd|keyboard'; then
            value="$(brightnessctl --device='*kbd*' -m 2>/dev/null |
                awk -F, 'NR == 1 { gsub(/%/, "", $4); print $4 }')"
            printf 'keyboard|1|%s\n' "${value:-0}"
        else
            printf 'keyboard|0|0\n'
        fi
        command -v hyprsunset >/dev/null 2>&1 \
            && printf 'nightlight|1|0\n' || printf 'nightlight|0|0\n'
        command -v hypridle >/dev/null 2>&1 \
            && printf 'idle|1|0\n' || printf 'idle|0|0\n'
        if command -v jq >/dev/null 2>&1 \
                && hyprctl monitors -j 2>/dev/null | jq -e 'length > 0' >/dev/null; then
            printf 'display|1|0\n'
        else
            printf 'display|0|0\n'
        fi
        ;;
    brightness)
        value="${2:?missing brightness percentage}"
        brightnessctl set "$(printf '%d' "$value")%" >/dev/null
        ;;
    keyboard)
        value="${2:?missing keyboard brightness percentage}"
        device="$(brightnessctl --list 2>/dev/null |
            sed -n "s/.*Device '\([^']*\)'.*/\1/p" | grep -iE 'kbd|keyboard' | head -n 1)"
        [[ -n "$device" ]] || exit 1
        brightnessctl --device="$device" set "$(printf '%d' "$value")%" >/dev/null
        ;;
    nightlight)
        enabled="${2:?missing enabled state}"
        temperature="${3:-4500}"
        systemctl --user stop ayame-night-light.service >/dev/null 2>&1 || true
        if [[ "$enabled" == 1 ]]; then
            systemd-run --user --unit=ayame-night-light.service \
                --property=Restart=on-failure --collect \
                hyprsunset -t "$temperature" >/dev/null
        fi
        ;;
    idle)
        enabled="${2:?missing enabled state}"
        timeout="${3:-600}"
        lock_enabled="${4:-1}"
        lock_command="pidof hyprlock || hyprlock --config $HOME/.local/share/ayame-shell/config/hyprlock/hyprlock.conf"
        config="$state_dir/hypridle.conf"
        {
            echo "general {"
            echo "    lock_cmd = $lock_command"
            echo "    before_sleep_cmd = loginctl lock-session"
            echo "}"
            echo "listener {"
            echo "    timeout = $timeout"
            if [[ "$lock_enabled" == 1 ]]; then
                echo "    on-timeout = loginctl lock-session"
            else
                echo "    on-timeout = hyprctl dispatch dpms off"
            fi
            echo "    on-resume = hyprctl dispatch dpms on"
            echo "}"
        } > "$config"
        systemctl --user stop ayame-idle.service >/dev/null 2>&1 || true
        if [[ "$enabled" == 1 ]]; then
            systemd-run --user --unit=ayame-idle.service \
                --property=Restart=on-failure --collect \
                hypridle -c "$config" >/dev/null
        fi
        ;;
    displays)
        hyprctl monitors -j | jq -r '.[] |
            [.name, (.description // .name),
             (.width|tostring), (.height|tostring),
             (.refreshRate|round|tostring), (.scale|tostring),
             (.x|tostring), (.y|tostring)] | join("|")'
        ;;
    display-modes)
        name="${2:?missing monitor name}"
        hyprctl monitors all -j | jq -r --arg name "$name" '
            .[] | select(.name == $name) | .availableModes[]' | sort -u
        ;;
    display-save)
        name="${2:?missing monitor name}"
        mode="${3:?missing mode}"
        scale="${4:?missing scale}"
        [[ "$name" =~ ^[A-Za-z0-9_.-]+$ ]] \
            || { echo "Invalid monitor name" >&2; exit 2; }
        [[ "$mode" =~ ^[0-9]+x[0-9]+@[0-9.]+(Hz)?$ ]] \
            || { echo "Invalid monitor mode" >&2; exit 2; }
        # `hyprctl monitors` labels advertised modes with a human-readable Hz
        # suffix, while hl.monitor() expects the numeric WxH@rate form.
        mode="${mode%Hz}"
        [[ "$scale" =~ ^[0-9]+([.][0-9]+)?$ ]] \
            || { echo "Invalid monitor scale" >&2; exit 2; }
        geometry="$(hyprctl monitors -j | jq -r --arg name "$name" '
            .[] | select(.name == $name) | "\(.x)x\(.y)"')"
        [[ "$geometry" =~ ^-?[0-9]+x-?[0-9]+$ ]] \
            || { echo "Could not resolve monitor position" >&2; exit 1; }
        # Hyprland 0.55+ monitor declarations are immutable rules in its Lua
        # configuration context. Live replacement can destabilize the
        # compositor and every layer-shell client, so persist the rule safely
        # and let the next normal Hyprland login apply it.
        monitor_state="$state_dir/monitors.lua"
        temporary="$(mktemp "$state_dir/monitors.lua.XXXXXX")"
        {
            echo "-- Generated by Ayame Display Controls."
            hyprctl monitors -j | jq -r \
                --arg selected "$name" --arg selectedMode "$mode" \
                --argjson selectedScale "$scale" '
                .[] | {
                    output: .name,
                    mode: (if .name == $selected then $selectedMode
                        else "\(.width)x\(.height)@\(.refreshRate)" end),
                    position: "\(.x)x\(.y)",
                    scale: (if .name == $selected then $selectedScale else .scale end)
                } | "hl.monitor({ output = \"\(.output)\", mode = \"\(.mode)\", position = \"\(.position)\", scale = \(.scale) })"'
        } > "$temporary"
        mv -- "$temporary" "$monitor_state"
        echo "saved"
        ;;
    *)
        echo "Usage: $0 {status|brightness N|keyboard N|nightlight 0|1 [K]|idle 0|1 [SEC] [LOCK]|displays|display-modes NAME|display-save NAME MODE SCALE}" >&2
        exit 2
        ;;
esac
