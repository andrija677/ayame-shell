# Optional Hyprland integration

Ayame does not edit the live Hyprland configuration during development. On
Hyprland 0.55+, load the optional Lua bindings from `hyprland.lua`:

```lua
dofile(os.getenv("HOME") .. "/Projects/ayame-shell/config/hypr/ayame-bindings.lua")
```

Reload Hyprland after adding it. Remove the line to roll it back. The eventual
installer will generate a path appropriate for the chosen installation prefix
instead of assuming the development repository lives under `~/Projects`.

`ayame-bindings.lua` contains the complete optional set shown by Ayame's Keybinds
window: launcher, close, fullscreen, floating, move/resize, and screenshot keys.
Review it before sourcing it. In particular, the monitor screenshot binding is
generated per machine because a hard-coded output name is not portable.
