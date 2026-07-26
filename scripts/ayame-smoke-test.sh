#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

check() {
    local label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        printf 'PASS  %s\n' "$label"
    else
        printf 'FAIL  %s\n' "$label"
        failures=$((failures + 1))
    fi
}

while IFS= read -r file; do
    check "Shell: ${file#"$root"/}" bash -n "$file"
done < <(find "$root/scripts" -name '*.sh' -type f -print; \
    printf '%s\n' "$root/install.sh" "$root/uninstall.sh")
# Distribution QML tools cannot resolve Quickshell modules and reject some of
# its valid JavaScript extensions. Catch the grouped-property terminator that
# Qt's live loader rejects, then let the live test validate the full graph.
if grep -RIn --include='*.qml' '};[[:space:]]*[A-Za-z]' \
        "$root/config/quickshell" >/dev/null; then
    printf 'FAIL  QML grouped-property separators\n'
    failures=$((failures + 1))
else
    printf 'PASS  QML grouped-property separators\n'
fi
check "Whitespace and patch artifacts" git -C "$root" diff --check
check "System control status contract" sh -c \
    "'$root/scripts/ayame-system-controls.sh' status | grep -q '^display|[01]|'"
check "Safe persistent monitor rules" grep -q 'let the next normal Hyprland login apply it' \
    "$root/scripts/ayame-system-controls.sh"
check "Diagnostics contract" sh -c \
    "'$root/scripts/ayame-doctor.sh' status | awk -F'|' 'NF != 4 { exit 1 }'"

if [[ "${1:-}" == "--live" ]]; then
    check "Ayame service active" systemctl --user is-active --quiet ayame-shell.service
    check "Notification smoke test" "$root/scripts/ayame-doctor.sh" test-notification
fi

((failures == 0)) || exit 1
printf 'Ayame smoke tests passed :3\n'
