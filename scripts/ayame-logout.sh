#!/usr/bin/env bash
set -euo pipefail

session_id="${XDG_SESSION_ID:-}"
if [[ -z "$session_id" ]] && command -v loginctl >/dev/null 2>&1; then
    session_id="$(loginctl show-user "$USER" -p Display --value 2>/dev/null || true)"
fi

[[ -n "$session_id" ]] || {
    echo "Could not identify the current logind session" >&2
    exit 1
}

switched=false
if command -v busctl >/dev/null 2>&1 \
        && busctl --system call \
        org.freedesktop.DisplayManager \
        /org/freedesktop/DisplayManager/Seat0 \
        org.freedesktop.DisplayManager.Seat \
        SwitchToGreeter >/dev/null 2>&1; then
    switched=true
fi

if [[ "$switched" != true ]] && command -v gdmflexiserver >/dev/null 2>&1; then
    if gdmflexiserver --startnew >/dev/null 2>&1; then
        switched=true
    fi
fi

if [[ "$switched" != true ]] && command -v dm-tool >/dev/null 2>&1; then
    dm-tool switch-to-greeter >/dev/null 2>&1 || true
fi

exec loginctl terminate-session "$session_id"
