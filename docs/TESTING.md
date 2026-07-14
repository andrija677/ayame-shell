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

If the terminal was closed, list Quickshell instances first:

```bash
qs list
```

Do not use `qs kill` without checking the list: another Quickshell config may
belong to the live desktop.

## Roll back project changes

Git records each working milestone. To inspect the history:

```bash
git -C "$HOME/Projects/ayame-shell" log --oneline
```

No rollback command should be run until its effect has been explained, because
some Git rollback commands can discard uncommitted work.
