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

printf -v post_command 'loginctl terminate-session %q' "$session_id"
exec hyprshutdown --no-exit --post-cmd "$post_command" \
    --top-label "Logging out of Ayame…"
