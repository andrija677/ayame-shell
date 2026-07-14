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
