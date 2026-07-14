# Optional Hyprland integration

Ayame does not edit the live Hyprland configuration during development. To test
keyboard activation manually, add a binding like this to your own configuration:

```ini
bind = SUPER, SPACE, exec, qs --path "$HOME/Projects/ayame-shell/config/quickshell" ipc call launcher toggle
```

Reload Hyprland after adding it. Remove the line to roll it back. The eventual
installer will generate a path appropriate for the chosen installation prefix
instead of assuming the development repository lives under `~/Projects`.

`ayame-bindings.conf` contains the complete optional set shown by Ayame's Keybinds
window: launcher, close, fullscreen, floating, move/resize, and screenshot keys.
Review it before sourcing it. In particular, the monitor screenshot binding is
generated per machine because a hard-coded output name is not portable.
