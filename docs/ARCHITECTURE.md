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

The root also creates one `AppDock` per screen. It displays running Hyprland
toplevels belonging to that monitor, resolves application icons through desktop
entries, and uses native Wayland activation/minimize requests. Right-clicking an
icon pins or unpins its desktop entry. Favorites persist through `ShellConfig`,
launch through the desktop entry when closed, and merge with their running window
instead of creating a duplicate icon. The dock overlays windows without reserving
a permanent bottom work area.

Optional intelligent hiding observes the active Hyprland workspace's fullscreen
state and live toplevel geometry directly. It intersects every window's live
global position with the dock's monitor-local bottom-center rectangle, so tiled,
split, and floating windows hide the dock whenever they would sit behind it.
Moving a window away from the dock reveals it immediately regardless of the
window's size.
When an obstructing window would sit behind the dock,
the surface slides below the bottom edge without destroying its window or app
model. A passive hover handler keeps a transparent bottom-edge sensor alive,
reveals the dock as the pointer approaches, and delays hiding briefly after the
pointer leaves to avoid oscillation. Non-obstructing window layouts keep the dock
visible, and opening the launcher temporarily holds it open.
Hyprland does not stream intermediate geometry for every pointer-driven move, so
one shell-root timer refreshes the shared toplevel model every 120 ms while the
feature is enabled. This makes Win-drag overlap responsive without spawning a
poller per monitor, and the timer stops entirely when the dock or option is off.

The dock's Ayame button owns a screen-local application launcher. Unlike small
bar popups, the launcher is a layer-shell overlay: this gives it reliable keyboard
focus whether it was opened by pointer input or compositor IPC, and lets a click
on the dimmed background dismiss it. It indexes freedesktop desktop entries in
memory, excludes entries marked `NoDisplay`, and filters names, generic names,
and keywords as the user types. Launching delegates to the desktop entry rather
than parsing its command in QML, preserving terminal, working-directory, and
field-code behavior.

The root exposes `launcher toggle`, `launcher open`, and `launcher close` through
Quickshell IPC. Requests target the dock on Hyprland's focused monitor. This gives
optional compositor bindings a stable interface without allowing Ayame's
development configuration to modify the user's live Hyprland files.
The generated default uses Hyprland's release-only modifier binding for
`SUPER_L`, opening the launcher when bare Super is released while preserving
Super combinations and Super-drag window controls.

Quick Settings opens a compositor-level Utilities surface with Keybinds and
Screenshot pages. Keybinds documents recovery-critical window controls including
the Super+Enter Kitty terminal, fullscreen toggle, floating toggle, and
Super-drag move/resize. Screenshot capture
delegates to a project script using `grim`, `slurp`, and `wl-copy`; it supports the
whole desktop, the current monitor, or an interactively selected region after
zero, three, or five seconds. Output goes to `Pictures/Screenshots`, is copied to
the clipboard, and is announced through the current notification service.

Weather is opt-in. `WeatherService` geocodes only explicit city searches, stores
the confirmed name and coordinates in ShellConfig, retrieves Open-Meteo forecasts,
and keeps the last response in Quickshell's cache directory for offline display.
The top bar owns a compact reading while the dashboard presents five forecast
days. Celsius is the default and no request occurs before setup.
The compact top-bar temperature also owns a screen-local forecast popup. It
reuses the dashboard's `WeatherCard`, so current conditions, apparent temperature,
wind, forecast days, cache state, and units stay consistent between both surfaces.

Ayame can choose and persist its own wallpaper through Hyprpaper, restore it at
login, and pass the same local image to Matugen. The chooser is rendered inside
Ayame and scans Pictures and Downloads, avoiding native-dialog layer-shell conflicts. Dynamic colors can also follow
an existing session that publishes ML4W's `current_wallpaper` cache file.
`DynamicPalette` watches that file, debounces changes, passes the image to Matugen,
and atomically swaps palettes after successful generation. A manual path remains
available as an override. Only generated color data is cached in Quickshell's
cache directory; the image is never uploaded or copied. Ayame Violet is a
persistent off mode, and tonal, vibrant, and expressive schemes share the same
semantic component API.
The optional Kitty fragment consumes the same semantic palette through a small
generated color include. Palette, light/dark, and Ayame Violet changes rewrite
that include atomically and signal running Kitty windows to reload; layout and
key mappings remain in a separate user-reviewable fragment.

Desktop replacement is deliberately separate from ordinary installation. The
explicit migration mode detaches only the active Hyprland and Quickshell config
roots into a timestamped state backup, creates a standalone Ayame Lua profile,
and generates a rollback script that first removes Ayame-owned integration and
then restores the exact original directories or symlinks. Related desktop data
is reported but not deleted, and the live compositor is never stopped mid-run.

Settings are separate from components. Components read typed feature flags from
`ShellConfig`, allowing modules to be disabled without editing their internal
layout or behavior. `ShellConfig` persists typed values atomically in
`Quickshell.dataDir/settings.json`, watches external changes, and debounces
writes. A graphical settings panel can use the same stable properties later.

The bar's audio control tracks PipeWire's current default sink. Audio state and
actions stay in the reusable component; the bar only decides where it appears.
The battery indicator follows UPower's display device and removes itself from
the layout when no laptop battery is present. Audio, battery, and tray feature
flags are independent.

System tray items live in a collapsible group so background applications do not
consume the whole right side of the bar. The group remains instantiated while
closed, allowing status changes to continue, but clips and disables its visual
footprint until the three-dot control is expanded. Native item activation, menus,
and scrolling remain delegated to each tray item.

Network status uses Quickshell's read-only NetworkManager backend. It reports
global connectivity for wired and fallback states, and adds signal strength
when a connected Wi-Fi network is available. A compact Canvas icon avoids icon
font dependencies, while its popup exposes passive connection details. Neither
surface changes connections.

The active-window label reads Hyprland's focused toplevel title directly. It is
confined to a responsive left area while an equal right area keeps the clock
centered. On wide displays each side may grow to 560 pixels, leaving substantially
more room for titles; narrower displays scale both regions down together. Only
titles longer than the resulting space use a conventional trailing ellipsis.

Workspace buttons follow the active Hyprland workspace. The familiar first page
shows 1–5; higher workspaces page in six-button groups (6–11, 12–17, and onward),
so externally selected workspaces remain visible without allowing an unbounded
row to push the active-window title or centered clock.

The clock is a reusable component rather than bar-owned markup. It emits its
interaction to the bar, which owns a screen-local dashboard popup. The dashboard
composes independent media and calendar cards.

The dashboard reads existing MPRIS players and an optional Ayame notification
server. Ownership defaults off during development so launching a preview beside
SwayNotificationCenter, Dunst, or another shell never steals its D-Bus name.
Once explicitly enabled for an Ayame-owned session, notifications are tracked for
history, queued into focused-monitor toasts, and exposed with native actions.
Do Not Disturb suppresses toasts but retains history. The dashboard shows the
three newest entries and Clear All removes the complete tracked model, preventing
an unbounded history from growing the popup beyond the screen.

Calendar events are stored atomically in `Quickshell.dataDir/events.json` via a
typed JSON adapter. One-time and yearly events share the same local model; the
editor writes only after an explicit save. No calendar data leaves the machine.
The store computes future occurrences for both one-time and yearly events, and
the dashboard highlights entries whose configured reminder window has begun.

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

Persistent personalization lives in `SettingsPopup`, reached from Quick
Settings but animated and owned as a separate surface. It controls color scheme,
wallpaper palette mode, surface tint, compositor blur, motion, density, shell
layout, tray policy, and weather. Quick Settings is reserved for immediate
session state: audio, Wi-Fi, Bluetooth, power profile, idle inhibition, gaming
mode, network state, and battery state.

Light and dark modes consume the matching semantic branch of the current
Matugen palette. Wallpaper tint blends the primary hue into surface roles while
preserving Matugen foreground contrast. Blur uses stable `ayame-shell-*`
layer-shell namespaces and applies or removes Hyprland layer rules at runtime;
the QML surfaces adjust opacity in tandem. No live Hyprland configuration file
is modified.

`SessionService` observes ML4W's existing gaming-mode marker and delegates
changes to its existing script. Keep Awake uses a Wayland idle inhibitor bound
to the bar window. Wi-Fi uses Quickshell's writable NetworkManager rfkill
property. Brightness controls are capability-driven and remain absent when
`brightnessctl` exposes no display-class backlight.

Power actions live in a dedicated layer-shell overlay opened from Quick Settings.
Lock starts Hyprlock with Ayame's project-local configuration; Log Out delegates
to Hyprshutdown for graceful application closure, while Restart and Shut Down delegate to systemd-logind through
`systemctl`. Lock is immediate, but every session-ending or machine-ending action
requires a separate confirmation state and warns about unsaved work. Commands are
never exercised by automated preview testing.
Hyprshutdown is allowed to fork for logout. It must outlive Quickshell because
closing desktop clients includes closing the process that launched it; foreground
mode would otherwise terminate the logout before Hyprland exits.

Hyprlock may write ordinary lifecycle messages to stderr, so Ayame uses its exit
code—not stderr presence—to detect failure. A successful unlock leaves the power
surface unmapped; only a nonzero exit reopens it with diagnostic text.

The Hyprlock configuration is self-contained and currently reads ML4W's local
blurred-wallpaper cache, matching Ayame's development environment. It provides a
centered clock, date, greeting, and rounded password surface using the same
Adwaita Sans typography and violet fallback palette. Installation work will
generate its wallpaper path and colors; the repository never overwrites the live
`~/.config/hyprlock.conf`.
