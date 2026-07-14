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

if command -v busctl >/dev/null 2>&1; then
    busctl --system call \
        org.freedesktop.DisplayManager \
        /org/freedesktop/DisplayManager/Seat0 \
        org.freedesktop.DisplayManager.Seat \
        SwitchToGreeter >/dev/null 2>&1 || true
fi

exec loginctl terminate-session "$session_id"
