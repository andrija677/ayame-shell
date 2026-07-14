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

1. Confirm connected Wi-Fi displays `WIFI` and its signal percentage.
2. Confirm a connected non-Wi-Fi route displays `NET`.
3. Disconnect networking and confirm `OFFLINE` appears in the error color.
4. Confirm captive-portal or limited connectivity uses the warning color.

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

For clock testing:

1. Click the clock and confirm the centered dashboard opens below the bar.
2. Confirm the clock expands to show the weekday and date while it is open.
3. Click it again and confirm the dashboard closes and clock compacts.
4. Confirm the clock remains centered throughout.

For dashboard testing:

1. Confirm the calendar highlights today and includes adjacent-month days.
2. Start an MPRIS-compatible player and confirm title and artist update.
3. Test previous, play/pause, and next when the player supports each action.
4. Confirm no notification popup behavior changes while Ayame is running.
5. Confirm opening unfolds downward from the clock with a top-center origin.
6. Confirm closing reverses fully before the popup window disappears.
7. Toggle repeatedly and confirm no half-open or invisible state remains.

## Stop the development shell

Press `Ctrl+C` in the terminal that started it.

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
