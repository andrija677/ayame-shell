# Ayame Shell

An original, modular Hyprland and Quickshell desktop shell for EndeavourOS.

The project is developed and tested outside `~/.config`. Nothing in this
repository is installed automatically.

## Current shell

Ayame currently includes a monitor-aware top bar and running-app dock, animated
dashboard with media, weather, calendar and local events, capability-driven
Quick Settings, persistent layout and reduced-motion preferences, and optional
wallpaper-following palettes generated locally by Matugen, with a manual image
override and the original Ayame Violet fallback. A dedicated Settings surface
owns persistent light/dark appearance, tint, blur, motion, density, and layout,
while Quick Settings focuses on live device and session controls.

## Test without installing

From a terminal inside the running Hyprland session:

```bash
qs --path "$HOME/Projects/ayame-shell/config/quickshell"
```

Stop it with `Ctrl+C` in the same terminal. This command does not modify the
live Hyprland or Quickshell configuration.

See [docs/TESTING.md](docs/TESTING.md) for troubleshooting and rollback steps.
