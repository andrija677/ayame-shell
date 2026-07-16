#!/usr/bin/env python3

import glob
import json
import os
import sys


def main() -> int:
    mode = sys.argv[1] if len(sys.argv) > 1 else "dark"
    home = os.path.expanduser("~")
    state_home = os.environ.get("XDG_STATE_HOME", os.path.join(home, ".local/state"))
    cache_home = os.environ.get("XDG_CACHE_HOME", os.path.join(home, ".cache"))
    wallpaper_file = os.path.join(state_home, "ayame-shell", "wallpaper.path")
    try:
        with open(wallpaper_file, encoding="utf-8") as handle:
            wallpaper = os.path.realpath(handle.read().strip())
    except OSError:
        return 1

    candidates = glob.glob(
        os.path.join(cache_home, "*", "by-shell", "*", "dynamic-palette.json")
    )
    candidates.sort(key=lambda path: os.path.getmtime(path), reverse=True)
    wanted = (
        "surface",
        "on_surface",
        "primary",
        "on_primary",
        "surface_container_high",
        "outline",
    )
    for path in candidates:
        try:
            with open(path, encoding="utf-8") as handle:
                data = json.load(handle)
            if os.path.realpath(data.get("wallpaper", "")) != wallpaper:
                continue
            colors = data["colors"]
            values = [colors[name][mode]["color"] for name in wanted]
            if all(isinstance(value, str) and len(value) == 7 for value in values):
                print("\n".join(values))
                return 0
        except (KeyError, OSError, TypeError, ValueError):
            continue
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
