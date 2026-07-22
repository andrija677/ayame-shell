#!/usr/bin/env bash
set -euo pipefail

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/ayame-shell/clipboard"
mkdir -p "$runtime_dir"

entry_line() {
    local id="${1:?missing clipboard id}"
    cliphist list | awk -F '\t' -v wanted="$id" '$1 == wanted { print; exit }'
}

password_payload() {
    wl-paste --list-types 2>/dev/null | grep -Eqi \
        '(^|/)(x-kde-passwordmanagerhint|x-keepass|x-1password)|password-manager'
}

case "${1:-list}" in
    watch)
        exec wl-paste --watch "$0" store
        ;;
    store)
        # Password managers advertise a private MIME hint alongside the actual
        # clipboard data. Never pass those payloads to cliphist.
        password_payload && exit 0
        exec cliphist store
        ;;
    list)
        cliphist list | while IFS=$'\t' read -r id preview; do
            [[ -n "$id" ]] || continue
            kind="text"
            path=""
            if [[ "$preview" == \[\[\ binary\ data* ]]; then
                path="$runtime_dir/$id"
                entry_line "$id" | cliphist decode > "$path"
                mime="$(file --brief --mime-type "$path" 2>/dev/null || true)"
                case "$mime" in
                    image/*) kind="image" ;;
                    *) kind="media" ;;
                esac
                preview="${mime:-Binary clipboard item}"
            fi
            preview="${preview//$'\r'/ }"
            preview="${preview//$'\n'/ }"
            preview="${preview//|/·}"
            printf '%s|%s|%s|%s\n' "$id" "$kind" "$preview" "$path"
        done
        ;;
    copy)
        line="$(entry_line "${2:?missing clipboard id}")"
        [[ -n "$line" ]] || exit 1
        printf '%s\n' "$line" | cliphist decode | wl-copy
        ;;
    delete)
        line="$(entry_line "${2:?missing clipboard id}")"
        [[ -n "$line" ]] || exit 0
        printf '%s\n' "$line" | cliphist delete
        rm -f -- "$runtime_dir/${2}"
        ;;
    clear)
        cliphist wipe
        find "$runtime_dir" -mindepth 1 -maxdepth 1 -type f -delete
        ;;
    *)
        echo "Usage: $0 {watch|store|list|copy ID|delete ID|clear}" >&2
        exit 2
        ;;
esac
