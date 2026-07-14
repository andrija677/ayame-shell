#!/usr/bin/env bash
set -euo pipefail

prefix="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
vt=3
if [[ -r "$prefix/sddm-vt" ]]; then
    IFS= read -r configured_vt < "$prefix/sddm-vt" || true
    [[ "${configured_vt:-}" =~ ^[0-9]+$ ]] && vt="$configured_vt"
fi

exec hyprshutdown --vt "$vt" --top-label "Logging out of Ayame…"
