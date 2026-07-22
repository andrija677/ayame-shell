#!/usr/bin/env bash
set -u

action="${1:-status}"
service="ayame-shell.service"

row() {
    local id="$1" label="$2" state="$3" detail="$4"
    detail="${detail//$'\n'/ }"
    detail="${detail//|//}"
    printf '%s|%s|%s|%s\n' "$id" "$label" "$state" "$detail"
}

case "$action" in
    restart)
        systemctl --user restart "$service"
        exit $?
        ;;
    test-notification)
        notify-send -a "Ayame Diagnostics" -t 5000 \
            "Notification test" "Ayame notification delivery is working :3" \
            >/dev/null 2>&1 &
        exit 0
        ;;
    status) ;;
    *) echo "Usage: $0 {status|restart|test-notification}" >&2; exit 2 ;;
esac

if systemctl --user is-active --quiet "$service"; then
    row service "Ayame service" healthy "Running with automatic crash recovery"
else
    row service "Ayame service" error "Not running"
fi

if pgrep -x qs >/dev/null 2>&1; then
    row quickshell "Quickshell" healthy "$(qs --version 2>/dev/null | head -n 1)"
else
    row quickshell "Quickshell" error "No qs process detected"
fi

hyprland_line="$(Hyprland --version 2>/dev/null | head -n 1 || true)"
if [[ "$hyprland_line" =~ Hyprland[[:space:]]+([0-9]+)\.([0-9]+) ]] \
        && ((BASH_REMATCH[1] > 0 || BASH_REMATCH[2] >= 55)); then
    row hyprland "Hyprland" healthy "$hyprland_line"
else
    row hyprland "Hyprland" error "${hyprland_line:-Missing}; Ayame requires 0.55+"
fi

notification_status="$(busctl --user status org.freedesktop.Notifications 2>/dev/null || true)"
if [[ "$notification_status" == *"CommandLine=qs "* ]]; then
    row notifications "Notifications" healthy "Ayame owns the notification service"
else
    row notifications "Notifications" warning "Another service may own notifications"
fi

if timeout 3 pw-dump >/dev/null 2>&1; then
    row pipewire "PipeWire" healthy "Audio and privacy inspection available"
else
    row pipewire "PipeWire" error "pw-dump could not reach PipeWire"
fi

if nmcli networking 2>/dev/null | grep -qx enabled; then
    row network "NetworkManager" healthy "Networking enabled"
else
    row network "NetworkManager" warning "Networking disabled or unavailable"
fi

if command -v cliphist >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1; then
    row clipboard "Clipboard support" healthy "cliphist and Wayland clipboard tools available"
else
    row clipboard "Clipboard support" unavailable "Install cliphist and wl-clipboard"
fi

if compgen -G '/sys/class/backlight/*' >/dev/null; then
    row brightness "Screen brightness" healthy "Kernel backlight detected"
elif command -v ddcutil >/dev/null 2>&1; then
    row brightness "Screen brightness" optional "No laptop backlight; DDC support available"
else
    row brightness "Screen brightness" unavailable "No supported backlight detected"
fi

if command -v hyprsunset >/dev/null 2>&1; then
    row nightlight "Night Light" healthy "hyprsunset available"
else
    row nightlight "Night Light" unavailable "Install hyprsunset"
fi

if command -v hypridle >/dev/null 2>&1; then
    row idle "Idle management" healthy "hypridle available"
else
    row idle "Idle management" unavailable "Install hypridle"
fi

required=(grim slurp wf-recorder wl-copy wl-paste cliphist kitty matugen rofi rofimoji curl pw-dump nmcli notify-send python3)
missing=()
for command_name in "${required[@]}"; do
    command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
done
if ((${#missing[@]} == 0)); then
    row dependencies "Core dependencies" healthy "All required commands found"
else
    row dependencies "Core dependencies" error "Missing: ${missing[*]}"
fi
