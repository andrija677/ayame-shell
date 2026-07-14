# Ayame Shell

An original, modular Hyprland and Quickshell desktop shell for EndeavourOS.

Please keep in mind that this is in beta, changes will occur in future releases.

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
An opt-in notification server provides queued popups, native actions, dashboard
history, dismiss/clear controls, and Do Not Disturb without taking ownership from
the user's current notification daemon during previews.
The Utilities surface documents recovery-friendly window keybinds and captures
the desktop, active monitor, or selected area instantly or after a countdown.
The searchable application launcher can be opened from the dock and exposes a
compositor-safe IPC toggle for an optional keyboard binding.
Fresh installations start with Ayame's bundled CC0 anime wallpaper; existing
wallpaper choices are preserved. Press `Super + .` to open the emoji picker,
then paste the copied emoji normally.
Prefix launcher input with `/` to run a shell command; the prefix is a launcher
cue and is not passed to the command. Desktop-entry metadata keeps graphical apps
such as Firefox direct, while terminal programs such as `btop` open in Kitty.
Quick Settings also opens a full-screen power surface with safe Lock, Log Out,
Restart, and Shut Down actions. The repository includes an Ayame Hyprlock design,
but does not replace the user's live lock configuration during development.
Log Out detects the active display-manager capabilities at runtime. Plasma Login
Manager, SDDM, GDM, and LightDM receive an explicit greeter handoff; greetd,
tuigreet, Ly, and other logind-managed sessions use the universal session-exit
fallback. Ayame does not install, replace, or enable a display manager.

## Test without installing

From a terminal inside the running Hyprland session:

```bash
qs --path "$HOME/Projects/ayame-shell/config/quickshell"
```

Stop it with `Ctrl+C` in the same terminal. This command does not modify the
live Hyprland or Quickshell configuration.

## Install

Inspect the scripts, then run:

```bash
./install.sh
```

The installer checks dependencies, previews its destination, backs up an existing
Ayame installation, installs under `~/.local/share/ayame-shell`, creates the
`~/.local/bin/ayame-shell` launcher, and optionally adds one backed-up Hyprland
source line. It never replaces existing Quickshell, Hyprlock, or Hypridle files.
On EndeavourOS and Arch Linux it offers to install missing core packages with
`pacman`, including Hyprland, Quickshell, Hyprlock, the screenshot tools, and
Kitty. Pass `--no-install-deps` to require a pre-provisioned system instead.
When Hyprland has no user configuration yet, the installer can create a minimal
Hyprland 0.55 Lua profile that loads Ayame and starts it only for Hyprland logins. It does not
autostart Ayame in KDE Plasma or other desktop sessions.
Autostart waits briefly for the graphical session and records diagnostics under
`~/.local/state/ayame-shell/startup.log`. Super+Enter opens Kitty, with
Ctrl+Alt+T available as a VM-friendly fallback.
A separately included Kitty fragment provides the Ayame Violet
terminal palette, spacing, transparency, and Ctrl+V clipboard paste without
replacing an existing Kitty configuration.
Kitty integration is enabled by default and follows Ayame's Matugen wallpaper
palette; pass `--no-kitty` to leave Kitty completely untouched.
Run the installed `uninstall.sh` to remove only Ayame-owned files and its generated
source line; pre-install backups are retained.

To deliberately replace an existing Hyprland and Quickshell desktop, use:

```bash
./install.sh --replace-desktop
```

This previews detected configs, moves the active `hypr` and `quickshell` roots
(including symlinks) into one timestamped state backup, installs a standalone
Ayame profile, and prints the path to a generated rollback script. Supporting
ML4W, Waybar, SwayNC, Hyprlock, and UWSM data is detected but left untouched.
The running session is never terminated by the installer; switch after logout.

See [docs/TESTING.md](docs/TESTING.md) for troubleshooting and rollback steps.
