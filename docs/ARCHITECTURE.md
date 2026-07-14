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

The root creates one `TopBar` per Quickshell screen. Each bar maps its screen to
the corresponding Hyprland monitor, so workspace selection is monitor-local and
the active-window title appears only on the currently focused monitor.

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
when a connected Wi-Fi network is available. A compact Canvas icon avoids icon
font dependencies, while its popup exposes passive connection details. Neither
surface changes connections.

The active-window label reads Hyprland's focused toplevel title directly. It is
confined to the fixed-width left area and elides long text so the centered clock
and right-side system area never shift.

The clock is a reusable component rather than bar-owned markup. It emits its
interaction to the bar, which owns a screen-local dashboard popup. The dashboard
composes independent media and calendar cards.

The dashboard reads existing MPRIS players but deliberately does not register a
notification server during development. Notification ownership will be enabled
only when Ayame can replace the current session shell without intercepting its
popups unexpectedly.

Calendar events are stored atomically in `Quickshell.dataDir/events.json` via a
typed JSON adapter. One-time and yearly events share the same local model; the
editor writes only after an explicit save. No calendar data leaves the machine.

Dashboard visibility is controlled by Ayame rather than popup focus dismissal.
This keeps the clock trigger reachable while the popup is open and ensures the
reverse animation completes before the backing window is hidden.

Quick Settings is a separate screen-local popup owned by the bar's right-side
trigger. It tracks PipeWire, NetworkManager connectivity, and UPower directly.
Opening it closes the center dashboard and vice versa, so major surfaces never
overlap.

Quick Settings device tiles are capability-driven. Bluetooth is omitted when
BlueZ exposes no adapter, connected counts come from its live device model, and
the performance profile is offered only when UPower reports support for it.
