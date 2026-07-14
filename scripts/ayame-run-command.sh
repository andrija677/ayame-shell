#!/usr/bin/env bash
set -euo pipefail

command_text="${1:-}"
[[ -n "$command_text" ]] || exit 2

first_word="${command_text%%[[:space:]]*}"
first_word="${first_word##*/}"
graphical=false
while IFS= read -r desktop_file; do
    exec_line="$(awk -F= '/^Exec=/ { print $2; exit }' "$desktop_file")"
    terminal="$(awk -F= '/^Terminal=/ { print tolower($2); exit }' "$desktop_file")"
    exec_word="${exec_line%%[[:space:]]*}"
    exec_word="${exec_word##*/}"
    if [[ "$exec_word" == "$first_word" && "$terminal" != "true" ]]; then
        graphical=true
        break
    fi
done < <(find /usr/share/applications "${XDG_DATA_HOME:-$HOME/.local/share}/applications" \
    -maxdepth 1 -type f -name '*.desktop' -print 2>/dev/null)

if [[ "$graphical" == true ]]; then
    sh -lc "$command_text" >/dev/null 2>&1 &
    exit 0
fi

kitty --title "Ayame Command" sh -lc \
    "$command_text; result=\$?; printf '\\n[command exited with status %s]\\n' \"\$result\"; exec \"\${SHELL:-/bin/sh}\"" \
    >/dev/null 2>&1 &
