# Testing and rollback

## Start the development shell

Run this from Kitty inside the active Hyprland session:

```bash
qs --path "$HOME/Projects/ayame-shell/config/quickshell"
```

Keep the terminal open while testing so warnings remain visible.

Click each workspace indicator as part of the test. Ayame Shell targets
Hyprland 0.55's Lua dispatcher syntax; legacy `workspace N` dispatch strings do
not work when Hyprland is running a Lua configuration.

For system tray testing:

1. Confirm icons appear on the right when tray applications are running.
2. Left-click an icon and confirm its normal action occurs.
3. Right-click an icon and confirm its native menu opens near the bar.
4. Middle-click or scroll only when the application normally supports it.

For audio testing:

1. Confirm the percentage follows the current default output volume.
2. Click the percentage and confirm mute toggles and displays `MUTE`.
3. Scroll over it and confirm volume changes in five-percent steps.
4. Confirm the control follows a newly selected default output device.

For battery testing on a laptop:

1. Confirm the percentage follows UPower's displayed battery percentage.
2. Connect power and confirm a `+` appears and the text uses the success color.
3. Disconnect power and confirm the `+` disappears.

The battery indicator should not reserve space on a desktop without a battery.

For network testing:

1. Confirm connected Wi-Fi displays signal arcs matching its strength.
2. Confirm a connected non-Wi-Fi route displays the globe icon.
3. Disconnect networking and confirm an error-colored cross appears.
4. Confirm captive-portal or limited connectivity uses the warning color.
5. Click the icon and confirm connection details appear below it.
6. Click it again and confirm the details close.

The indicator is passive and must not change NetworkManager state.

For active-window testing:

1. Focus windows with short and long titles and confirm the label follows them.
2. Confirm long titles elide instead of overlapping the centered clock.
3. Switch to an empty workspace and confirm no stale title remains.

For multi-monitor testing:

1. Confirm exactly one bar appears on each connected screen.
2. Switch workspaces independently and confirm each bar highlights its monitor's
   active workspace.
3. Move focus between monitors and confirm the window title appears only on the
   focused monitor.
4. Disconnect and reconnect a screen and confirm its bar follows it.

For dock testing:

1. Confirm one centered dock appears on each screen containing windows.
2. Open and close applications and confirm items enter and leave live.
3. Click an inactive item and confirm its window activates.
4. Click the active item and confirm its window minimizes.
5. Confirm active and urgent indicators update, icons resolve where desktop
   entries exist, and hover motion does not clip.
6. Move a window between monitors and confirm its item follows the window.
7. Toggle Dock in Quick Settings, restart Ayame, and confirm visibility persists.

For weather testing:

1. Confirm no weather request or widget appears before a city is configured.
2. Search a city, choose the correct region/country result, and confirm the bar
   and dashboard populate.
3. Confirm Celsius is the initial unit; toggle units and verify a fresh forecast.
4. Restart Ayame and confirm the location, units, and cached forecast persist.
5. Disconnect networking and confirm cached data remains with a stale/offline
   indication rather than disappearing.
6. Use manual refresh and confirm concurrent requests are prevented.
7. Forget the location and confirm widgets disappear, settings clear, and no
   further scheduled forecast request occurs.

For standalone wallpaper testing, use WALLPAPER beside Wallpaper colors and pick
a PNG, JPEG, or WebP from the in-shell Pictures and Downloads list. The Browse
button inside COLORS must open the same picker. Hyprpaper must update all
untargeted monitors, the chosen absolute path must persist, and Ayame plus Kitty
must receive the generated palette. Restart the Hyprland session and confirm the
wallpaper is restored without ML4W being installed.
Close the picker and confirm the wallpaper stays unchanged and Quickshell remains
running.
Log out, restart, and shut down after selecting a wallpaper. The persisted image
must be present as Hyprpaper starts, and Hyprland's default logo or wallpapers
must never flash while Ayame starts or exits.

For clock testing:

1. Click the clock and confirm the centered dashboard opens below the bar.
2. Confirm the clock expands to show the weekday and date while it is open.
3. Click it again and confirm the dashboard closes and clock compacts.
4. Confirm the clock remains centered throughout.

For dashboard testing:

1. Confirm the calendar highlights today and includes adjacent-month days.
2. Start an MPRIS-compatible player and confirm title and artist update.
3. Test previous, play/pause, and next when the player supports each action.
4. Confirm artwork loads when supplied and the fallback note appears otherwise.
5. Confirm playback time advances once per second and clicking the progress track
   seeks only when the player supports seeking.
6. Confirm no notification popup behavior changes while Ayame is running.
7. Confirm opening unfolds downward from the clock with a top-center origin.
8. Confirm closing reverses fully before the popup window disappears.
9. Toggle repeatedly and confirm no half-open or invisible state remains.
10. Confirm the first closing click both reverses the animation and compacts the
   clock date; a second cleanup click must never be necessary.

For calendar event testing:

1. Select a day, add a titled event, save it, and confirm a day marker appears.
2. Close and restart Ayame and confirm the event persists locally.
3. Add a yearly event and confirm it appears on the same month/day in another
   year.
4. Remove an event and confirm its marker disappears when no events remain.
5. Cancel the editor and confirm no file data changes.
6. Choose each reminder lead time and confirm it persists with the event.
7. Confirm events in the next 30 days appear in Upcoming, ordered by date.
8. Confirm yearly events use their next future occurrence rather than the year
   originally stored.
9. Navigate to previous and next months and confirm event markers recompute.
10. Press Today and confirm both the visible month and selected date return to
    the current day.
11. Confirm later months travel left and enter from the right, while earlier
    months move in the opposite direction.
12. Repeatedly navigate and confirm the calendar never gets stuck invisible or
    horizontally offset.

For Quick Settings testing:

1. Click the sliders icon at the right and confirm the panel unfolds from its
   top-right corner.
2. Drag and click the volume track and confirm PipeWire volume follows it.
3. Toggle mute and confirm both the bar and panel update.
4. Confirm network and available battery state update live.
5. Open the clock dashboard, then Quick Settings, and confirm only one remains
   open; repeat in the opposite order.
6. Click the sliders icon again and confirm the reverse animation completes.
7. If Bluetooth hardware exists, toggle its tile and confirm adapter power and
   connected-device count update; otherwise confirm no empty tile remains.
8. Switch between available power profiles and confirm the selected pill and
   system profile agree. Performance must appear only when supported.

Bluetooth hardware alone is not sufficient: BlueZ must expose an adapter over
D-Bus. Ayame does not start or enable the privileged `bluetooth.service`; when
that service is inactive, the tile remains absent by design.

## Stop the development shell

Press `Ctrl+C` in the terminal that started it.

## Persistent settings

Settings are stored in Quickshell's private Ayame data directory as
`settings.json`. To test persistence, change a `ShellConfig` property through a
future settings UI or a temporary development binding, restart Ayame, and confirm
the value remains. External valid JSON edits should reload while Ayame runs.

Do not delete or hand-edit the file during normal testing without first backing
it up; `ShellConfig.resetDefaults()` intentionally restores all defaults.

The initial Quick Settings preferences toggle the active-window title and passive
tray visibility. Change one, wait briefly for the debounced write, restart Ayame,
and confirm both the visual state and toggle selection persist.

Toggle Animations off and exercise the bar, dashboard, calendar, Quick Settings,
and dock. State changes must remain correct and immediate with no stuck popup or
partially transformed component. Re-enable it and confirm motion returns without
a restart.

Toggle Compact layout and confirm the bar, dock, dashboard, and Quick Settings
reflow immediately with tighter spacing. Restart Ayame and confirm the selected
density persists, then return to comfortable spacing and check that no text is
clipped.

Open Wallpaper colors in Quick Settings, enter an absolute path to a local PNG,
JPEG, or WebP image, choose a palette style, and generate it. Confirm the shell
recolors without a restart, text remains readable, and the selected palette
persists after restarting Ayame. Change the style and regenerate, then choose
Use Ayame Violet and confirm the original palette returns immediately. Invalid
and missing paths must show an error without replacing the last valid palette.

Dynamic palette output is stored under Quickshell's private cache directory as
`dynamic-palette.json`. The wallpaper itself must not be copied into Ayame's data
or cache directories.

Select Follow Wallpaper, change the wallpaper through ML4W, and confirm Ayame
regenerates its palette without a shell restart or manual refresh. The previous
colors must remain active while Matugen runs. Restart in Follow Wallpaper mode
and confirm the current image is detected from ML4W's cache. Select Ayame Violet,
restart once more, and confirm automatic following remains disabled until the
user explicitly selects it again.
With the Ayame Kitty fragment enabled, confirm Kitty follows generated wallpaper
colors and light/dark changes without restarting. Returning to Ayame Violet must
restore the fallback terminal palette, Ctrl+V must paste, and an existing Kitty
configuration must remain intact apart from its backed-up include line.

Open Quick Settings and then Ayame Settings. Switch between Dark and Light and
confirm every foreground remains readable, including inactive pills and nested
setup windows. Toggle Wallpaper tint and verify large surfaces become more or
less influenced by the generated primary color without changing accents.

Toggle Background blur and confirm the bar, dock, dashboard, and popups become
translucent with Hyprland blur behind them. Disable it and verify surfaces return
to near-opaque colors and the runtime layer rule is removed. Restart in both
states to verify persistence. Ayame must not edit the user's Hyprland files.

Confirm persistent layout, motion, palette, and weather controls no longer
appear directly in Quick Settings. Its Networking master and Wi-Fi tiles must
follow NetworkManager state; do not test them while connectivity is needed.
Keep Awake must inhibit idle only while selected and reset when Ayame exits.
Gaming Mode must reflect ML4W's marker, remain disabled while its script runs,
and update after the script completes. Brightness must be omitted when no display
backlight is available.

Click the top-bar temperature and confirm a forecast unfolds beneath it with the
configured city, current condition, temperature, apparent temperature, wind,
five forecast days, rain probabilities, and cached/fresh state. Click it again
to verify the reverse animation. Opening the dashboard or Quick Settings must
close the weather popup, while the dashboard's own forecast remains available.

Switch from workspace 1–5 to workspace 6 and confirm the bar changes to 6–11.
Workspace 12 must change the page to 12–17, and larger IDs must continue the same
six-workspace pattern. Return to workspace 1 and confirm the original 1–5 page.
Open a window with a title wider than the remaining left-side space. The title
must use the expanded responsive region and, only if it still cannot fit, end in
an ellipsis without moving the centered clock. Resize across display widths and
confirm the left and right regions remain balanced.

While Ayame Settings is open, the top-bar Quick Settings trigger must remain in
its active state. Clicking it must close Settings rather than stacking Quick
Settings above it. Opening the clock dashboard must also close either right-side
surface before the dashboard appears.

Launch tray applications with different menus, such as Discord and Steam. A
left or right click on an item that publishes a menu must open its own actions at
the tray icon, including application-provided quit and status entries. A tray
item without a menu must retain normal primary activation, middle-click must
retain secondary activation, and wheel events must continue reaching the item.
Collapse the tray with its upward arrow and confirm the application icons animate
into a compact three-dot control without shifting the centered clock. Expand it
again and confirm every icon and native menu still works.

Right-click a running application in the dock and confirm it remains as a
favorite after the window closes. Left-click the favorite to launch it, then
confirm the running window reuses the same icon rather than adding a duplicate.
Left-click the active icon to minimize and click it again to restore/focus it.
Restart Ayame and confirm the favorite remains. Right-click it again to unpin it;
once its window closes, the icon must leave the dock.

Enable Intelligent dock hide in Ayame Settings. Maximize or fullscreen a window
on one monitor and confirm that monitor's dock slides completely below the bottom
edge. Move the pointer into the dock's usual bottom-center region and confirm it
slides back smoothly, remains present while hovered, then hides after a short
leave delay. Restore or unmaximize the window and confirm the dock stays visible.
Also test one large tiled window (which Hyprland reports as non-fullscreen) and a
split layout; any window that intersects the dock's bottom-center rectangle must
hide it. Move a floating window upward or sideways until it no longer intersects
that rectangle; the dock must reappear as soon as the move state updates during
the live Win-drag, then hide again if the window is moved back over it. Disable
Intelligent dock hide and confirm the geometry refresh loop stops.
Opening the launcher must hold the dock open. On multiple monitors, obstruction
and reveal behavior must remain monitor-local. Disable the option and confirm the
dock returns to always-visible behavior.

Click the nine-dot application grid at the start of the dock. Confirm the launcher unfolds above
the dock and places keyboard focus in Search. Search using an application's name,
generic name, and keyword; hidden desktop entries must not appear. Press Enter to
launch the first result, or use arrow keys and Enter to launch another result.
Entries whose icon is absent from the active system theme must show an Ayame
initial tile rather than Qt's black/magenta missing-texture placeholder.
Press Up from the first result to return to Search, then type while a result has
focus and confirm the text is forwarded into Search. Press Escape and confirm the
launcher reverses its animation before disappearing.

Exercise the launcher's compositor-safe interface while Ayame is running:

```bash
qs --path "$HOME/Projects/ayame-shell/config/quickshell" ipc call launcher toggle
qs --path "$HOME/Projects/ayame-shell/config/quickshell" ipc call launcher close
```

Confirm the overlay opens on the focused monitor, Search receives keyboard input,
and the terminal reports no popup-parent or input-serial warnings. The optional
Hyprland binding in `config/hypr/README.md` must call the same interface.

Open Quick Settings and select Power. Confirm the full-screen surface offers Lock,
Log Out, Restart, and Shut Down. Clicking Log Out, Restart, or Shut Down must show
the matching confirmation state and an unsaved-work warning; Cancel must return
without executing anything. Escape and a background click must close the surface.
After saving work, confirm Log Out starts Hyprshutdown and returns to the display
manager rather than invoking the removed legacy `hyprctl dispatch exit` syntax.
Hyprshutdown must run in its default forked mode so closing Quickshell cannot
terminate the logout before Hyprland exits.
On SDDM, logout must switch to VT2 and reveal the greeter instead of leaving the
display on Hyprland's dead VT. Verify the installed sudoers entry permits only
`/usr/bin/chvt 2`, and confirm uninstall removes that entry.

Do not confirm a destructive action during ordinary preview testing. Test Lock
only after saving work: it must start `config/hyprlock/hyprlock.conf`, show the
wallpaper, clock, date, username greeting, and password field, reject an incorrect
password visibly, and return to the same session after correct authentication.
After a successful unlock, the power surface must remain completely absent rather
than flashing behind Hyprlock or replaying a close transition. Normal Hyprlock
stderr output must not be presented as an error; a nonzero exit may reopen the
surface with its diagnostic text.
Inspect the project lock configuration directly rather than copying it over the
user's live Hyprlock configuration.

If the terminal was closed, list Quickshell instances first:

```bash
qs list
```

Do not use `qs kill` without checking the list: another Quickshell config may
belong to the live desktop.

Before enabling Ayame notifications, inspect the current owner with
`busctl --user status org.freedesktop.Notifications`. Do not enable ownership in
a development preview while another daemon is responsible for the live session.
In an Ayame-owned test session, enable the service in Settings and send several
notifications with bodies and actions. Confirm popups queue on the focused
monitor, expire while retaining history, actions invoke, individual dismiss and
Clear All remove tracked entries, and the dashboard shows at most the newest
three. With Do Not Disturb enabled, new entries must reach history without a
popup. Disable notification ownership before returning to another session shell.

Open Quick Settings → Keybinds and confirm all launcher, window recovery, and
screenshot shortcuts fit without clipping. Verify Super+Enter opens Kitty,
Ctrl+Alt+T provides the same recovery path in a VM, and Super+F toggles fullscreen,
Super+Shift+F returns a window to floating, and Super+left-drag can move it from
any visible point. These bindings remain documentation until the optional Hyprland
file is explicitly sourced.
With the optional bindings enabled, tap and release bare Super to toggle the
launcher. Holding Super for another shortcut or window drag must retain its normal
behavior rather than opening the launcher prematurely.
Verify Super+1 through Super+5 switch directly to the matching workspace and
Super+Shift+1 through Super+Shift+5 move the active window there. Neither action
may trigger the bare-Super launcher after the combination is released.

Open Screenshot and test desktop, monitor, and area modes with instant, 3-second,
and 5-second timing. Area cancellation must create no file. Successful captures
must appear under `Pictures/Screenshots`, enter the image clipboard, and notify the
user. Never place unsanitized user text into a shell command.

## Roll back project changes

Git records each working milestone. To inspect the history:

```bash
git -C "$HOME/Projects/ayame-shell" log --oneline
```

No rollback command should be run until its effect has been explained, because
some Git rollback commands can discard uncommitted work.

## Installer sandbox test

Never point installer tests at the live configuration. Use a temporary HOME and
stub required commands, then verify the generated prefix, launcher, Hyprland
fragment, source-line backup, and uninstall behavior. A real install must preview
its paths and ask before changing `hyprland.lua`; reinstall must move the previous
Ayame prefix to a timestamped backup rather than overwriting it.
On a clean EndeavourOS installation, confirm the installer lists missing commands
and their Arch package names before requesting permission to run `pacman`.
Declining or passing `--no-install-deps` must leave the system unchanged and exit
with instructions. After accepting, every required command must be rechecked
before Ayame files are installed.
Test once with no `hyprland.lua`: accepting profile creation must produce a
minimal marked file that sources Ayame, and a Hyprland login must start the shell.
Ayame must not autostart in KDE Plasma. Uninstall must remove an untouched minimal
profile, but preserve a profile to which the user added any other configuration.
Confirm installation runs Hyprland's offline configuration validator. A Hyprland
login must start Ayame after a short session-ready delay and write failures to
`~/.local/state/ayame-shell/startup.log`; KDE must not start Ayame or create that
log.

## Desktop replacement test

Run `./install.sh --replace-desktop` only in an isolated home or disposable VM.
The preview must identify existing Hyprland and Quickshell directories or
symlinks, report related desktop data that will remain untouched, and name the
timestamped backup before confirmation. After accepting, the old active roots
must exist under `~/.local/state/ayame-shell/migrations/.../original-config`, a
standalone `hyprland.lua` must validate, and the live session must remain running.
After logout, only Ayame may start. Run the printed `restore.sh`, confirm it again,
and verify the exact old directories or symlinks return while the displaced Ayame
configuration remains inside the migration backup for inspection.
