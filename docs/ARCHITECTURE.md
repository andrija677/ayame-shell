# Architecture

Ayame Shell keeps presentation, system integration, and theme values separate.

- `config/quickshell/components`: small reusable visual components
- `config/quickshell/modules`: complete areas of the shell, such as the bar
- `config/quickshell/services`: system and compositor data sources
- `config/quickshell/settings`: user-facing feature defaults and settings data
- `config/quickshell/theme`: shared colors, dimensions, and animation values
- `config/hypr`: future optional Hyprland integration
- `config/hyprlock`: future lock-screen configuration
- `config/hypridle`: future idle configuration
- `scripts`: future helper scripts
- `assets`: project-owned artwork, icons, images, and wallpapers
- `themes`: future theme presets

The root `shell.qml` is deliberately small. It assembles modules but does not
contain their implementation details.

Settings are separate from components. Components read typed feature flags from
`ShellConfig`, allowing modules to be disabled without editing their internal
layout or behavior. Persistent overrides and a graphical settings panel are
planned later.

The bar's audio control tracks PipeWire's current default sink. Audio state and
actions stay in the reusable component; the bar only decides where it appears.
The battery indicator follows UPower's display device and removes itself from
the layout when no laptop battery is present. Audio, battery, and tray feature
flags are independent.

Network status uses Quickshell's read-only NetworkManager backend. It reports
global connectivity for wired and fallback states, and adds signal strength
when a connected Wi-Fi network is available. It never changes connections.

The active-window label reads Hyprland's focused toplevel title directly. It is
confined to the fixed-width left area and elides long text so the centered clock
and right-side system area never shift.
