# Ayame Shell

An original, modular Hyprland and Quickshell desktop shell for EndeavourOS.

The project is developed and tested outside `~/.config`. Nothing in this
repository is installed automatically.

## Current milestone

The first milestone is a minimal top bar containing:

- Hyprland workspace indicators
- a centered clock
- a small system area

## Test without installing

From a terminal inside the running Hyprland session:

```bash
qs --path "$HOME/Projects/ayame-shell/config/quickshell"
```

Stop it with `Ctrl+C` in the same terminal. This command does not modify the
live Hyprland or Quickshell configuration.

See [docs/TESTING.md](docs/TESTING.md) for troubleshooting and rollback steps.

