#!/usr/bin/env bash
set -euo pipefail

action="${1:-status}"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ayame-shell"
state_file="$state_dir/legacy-notification-services"
services=(swaync.service dunst.service mako.service fnott.service)

case "$action" in
    apply)
        mkdir -p "$state_dir"
        : >"$state_file"
        for service in "${services[@]}"; do
            systemctl --user cat "$service" >/dev/null 2>&1 || continue
            enabled=false
            active=false
            systemctl --user is-enabled --quiet "$service" && enabled=true
            systemctl --user is-active --quiet "$service" && active=true
            printf '%s\t%s\t%s\n' "$service" "$enabled" "$active" >>"$state_file"
            systemctl --user mask --now "$service" >/dev/null
            echo "Disabled conflicting notification service: $service"
        done
        ;;
    restore)
        [[ -f "$state_file" ]] || exit 0
        while IFS=$'\t' read -r service enabled active; do
            [[ -n "$service" ]] || continue
            systemctl --user unmask "$service" >/dev/null 2>&1 || true
            if [[ "$enabled" == true ]]; then
                systemctl --user enable "$service" >/dev/null 2>&1 || true
            fi
            if [[ "$active" == true ]]; then
                systemctl --user start "$service" >/dev/null 2>&1 || true
            fi
        done <"$state_file"
        rm -f "$state_file"
        ;;
    status)
        if [[ -s "$state_file" ]]; then
            echo "Ayame owns notifications; legacy services are recoverably masked."
        else
            echo "No Ayame notification-service takeover is recorded."
        fi
        ;;
    *)
        echo "Usage: $0 {apply|restore|status}" >&2
        exit 2
        ;;
esac
