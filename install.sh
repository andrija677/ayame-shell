#!/usr/bin/env bash
set -euo pipefail

prefix="${XDG_DATA_HOME:-$HOME/.local/share}/ayame-shell"
assume_yes=false
install_dependencies=true
replace_desktop=false
for argument in "$@"; do
    case "$argument" in
        --yes) assume_yes=true ;;
        --no-install-deps) install_dependencies=false ;;
        --replace-desktop) replace_desktop=true ;;
        --prefix=*) prefix="${argument#*=}" ;;
        *) echo "Unknown option: $argument" >&2; exit 2 ;;
    esac
done

source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${XDG_BIN_HOME:-$HOME/.local/bin}"
hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
hypr_main="$hypr_dir/hyprland.lua"
hypr_fragment="$hypr_dir/ayame-shell.lua"
kitty_dir="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
kitty_main="$kitty_dir/kitty.conf"
kitty_fragment="$kitty_dir/ayame-shell.conf"
timestamp="$(date +%Y%m%d-%H%M%S)"
migration_backup=""
sudoers_file="/etc/sudoers.d/ayame-hyprshutdown-${USER}"

required=(qs hyprctl hyprlock hyprpaper hyprshutdown grim slurp wl-copy kitty)
declare -A command_packages=(
    [qs]=quickshell
    [hyprctl]=hyprland
    [hyprlock]=hyprlock
    [hyprpaper]=hyprpaper
    [hyprshutdown]=hyprshutdown
    [grim]=grim
    [slurp]=slurp
    [wl-copy]=wl-clipboard
    [kitty]=kitty
)
missing=()
for command_name in "${required[@]}"; do
    command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
done
if ((${#missing[@]})); then
    printf 'Missing required commands: %s\n' "${missing[*]}"
    missing_packages=()
    for command_name in "${missing[@]}"; do
        package_name="${command_packages[$command_name]}"
        [[ " ${missing_packages[*]} " == *" $package_name "* ]] \
            || missing_packages+=("$package_name")
    done
    printf 'Packages needed: %s\n' "${missing_packages[*]}"

    if [[ "$install_dependencies" != true ]]; then
        echo "Dependency installation was disabled with --no-install-deps." >&2
        exit 1
    fi
    if ! command -v pacman >/dev/null 2>&1; then
        echo "Automatic dependencies currently require Arch Linux or EndeavourOS with pacman." >&2
        exit 1
    fi
    if [[ "$assume_yes" == true ]]; then
        dependency_answer=y
    else
        read -r -p "Install the missing packages with pacman now? [y/N] " dependency_answer
    fi
    if [[ ! "$dependency_answer" =~ ^[Yy]$ ]]; then
        echo "Install the listed packages, then run this installer again." >&2
        exit 1
    fi
    sudo pacman -S --needed "${missing_packages[@]}"

    still_missing=()
    for command_name in "${required[@]}"; do
        command -v "$command_name" >/dev/null 2>&1 || still_missing+=("$command_name")
    done
    if ((${#still_missing[@]})); then
        printf 'Commands still missing after package installation: %s\n' \
            "${still_missing[*]}" >&2
        exit 1
    fi
fi

if command -v pacman >/dev/null 2>&1 \
        && ! pacman -Q ttf-jetbrains-mono-nerd >/dev/null 2>&1; then
    if [[ "$assume_yes" == true ]]; then
        font_answer=y
    else
        read -r -p "Install JetBrainsMono Nerd Font for Ayame and Kitty? [y/N] " font_answer
    fi
    if [[ "$font_answer" =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed ttf-jetbrains-mono-nerd
    fi
fi

echo "Ayame Shell installer"
echo "  Source:      $source_dir"
echo "  Destination: $prefix"
echo "  Launcher:    $bin_dir/ayame-shell"
echo "  Hyprland:    $hypr_fragment"
if [[ "$assume_yes" != true ]]; then
    read -r -p "Continue? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 0
fi

sudoers_temporary="$(mktemp)"
printf '%s ALL=(root) NOPASSWD: /usr/bin/chvt 2\n' "$USER" > "$sudoers_temporary"
if ! sudo cmp -s "$sudoers_temporary" "$sudoers_file" 2>/dev/null; then
    echo "Configuring the SDDM VT2 handoff used by Ayame Log Out."
    sudo install -o root -g root -m 0440 "$sudoers_temporary" "$sudoers_file"
fi
rm -f "$sudoers_temporary"

if [[ "$replace_desktop" == true ]]; then
    config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    migration_backup="${XDG_STATE_HOME:-$HOME/.local/state}/ayame-shell/migrations/$timestamp"
    replace_paths=("$config_home/hypr" "$config_home/quickshell")
    related_paths=(waybar swaync hypridle hyprlock ml4w uwsm)

    echo
    echo "Desktop replacement preview"
    echo "  Backup: $migration_backup"
    for path in "${replace_paths[@]}"; do
        if [[ -L "$path" ]]; then
            echo "  Detach symlink: $path -> $(readlink -- "$path")"
        elif [[ -e "$path" ]]; then
            echo "  Detach config:  $path"
        else
            echo "  Not present:    $path"
        fi
    done
    for name in "${related_paths[@]}"; do
        [[ -e "$config_home/$name" || -L "$config_home/$name" ]] \
            && echo "  Preserve related data: $config_home/$name"
    done
    echo "The current session will not be stopped; Ayame takes over after logout."
    if [[ "$assume_yes" == true ]]; then
        replace_answer=y
    else
        read -r -p "Back up the active desktop configs and replace them with Ayame? [y/N] " replace_answer
    fi
    [[ "$replace_answer" =~ ^[Yy]$ ]] || exit 0

    mkdir -p "$migration_backup/original-config"
    for path in "${replace_paths[@]}"; do
        if [[ -e "$path" || -L "$path" ]]; then
            mv -- "$path" "$migration_backup/original-config/$(basename -- "$path")"
        fi
    done

    cat > "$migration_backup/restore.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
backup_dir="\$(cd -- "\$(dirname -- "\${BASH_SOURCE[0]}")" && pwd)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
stamp="\$(date +%Y%m%d-%H%M%S)"
echo "This removes the current Ayame installation and restores the previous Hyprland and Quickshell configs."
read -r -p "Continue with rollback? [y/N] " answer
[[ "\$answer" =~ ^[Yy]$ ]] || exit 0
if [[ -x "$prefix/uninstall.sh" ]]; then
    "$prefix/uninstall.sh" --yes --prefix="$prefix"
fi
for name in hypr quickshell; do
    current="\$config_home/\$name"
    original="\$backup_dir/original-config/\$name"
    if [[ -e "\$current" || -L "\$current" ]]; then
        mv -- "\$current" "\$backup_dir/ayame-config-\$name-\$stamp"
    fi
    if [[ -e "\$original" || -L "\$original" ]]; then
        mv -- "\$original" "\$current"
    fi
done
echo "Previous desktop configuration restored. Log out and back in."
EOF
    chmod +x "$migration_backup/restore.sh"
fi

mkdir -p "$(dirname -- "$prefix")" "$bin_dir" "$hypr_dir" "$kitty_dir"
if [[ -e "$prefix" ]]; then
    backup="${prefix}.backup-${timestamp}"
    echo "Backing up the previous Ayame installation to $backup"
    mv -- "$prefix" "$backup"
fi

mkdir -p "$prefix"
cp -a "$source_dir/assets" "$source_dir/config" "$source_dir/docs" \
    "$source_dir/scripts" "$source_dir/themes" "$source_dir/README.md" \
    "$source_dir/uninstall.sh" "$prefix/"
chmod +x "$prefix/scripts/ayame-screenshot.sh" \
    "$prefix/scripts/ayame-kitty-colors.sh" \
    "$prefix/scripts/ayame-wallpaper.sh" "$prefix/uninstall.sh"

install -m 0644 "$prefix/config/kitty/ayame-shell.conf" "$kitty_fragment"
install -m 0644 "$prefix/config/kitty/ayame-colors.conf" "$kitty_dir/ayame-colors.conf"
if ! grep -Fq "include $kitty_fragment" "$kitty_main" 2>/dev/null; then
    if [[ "$assume_yes" == true ]]; then
        kitty_answer=y
    else
        read -r -p "Enable the Ayame Kitty design and Ctrl+V paste? [y/N] " kitty_answer
    fi
    if [[ "$kitty_answer" =~ ^[Yy]$ ]]; then
        if [[ -f "$kitty_main" ]]; then
            cp -a "$kitty_main" "$kitty_main.ayame-backup-$timestamp"
            printf '\n# Ayame Shell\ninclude %s\n' "$kitty_fragment" >> "$kitty_main"
        else
            printf '# Created by Ayame Shell.\ninclude %s\n' "$kitty_fragment" > "$kitty_main"
        fi
        echo "Enabled the Ayame Kitty design."
    fi
fi

cat > "$bin_dir/ayame-shell" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "--autostart" ]]; then
    shift
    state_dir="\${XDG_STATE_HOME:-\$HOME/.local/state}/ayame-shell"
    mkdir -p "\$state_dir"
    sleep 1
    exec qs --path "$prefix/config/quickshell" "\$@" >>"\$state_dir/startup.log" 2>&1
fi
exec qs --path "$prefix/config/quickshell" "\$@"
EOF
chmod +x "$bin_dir/ayame-shell"

monitor="$(hyprctl monitors 2>/dev/null | awk '/^Monitor / {print $2; exit}' || true)"
cat > "$hypr_fragment" <<EOF
-- Generated by Ayame Shell. Edit or remove safely.
local ayame = "$bin_dir/ayame-shell"
local screenshot = "$prefix/scripts/ayame-screenshot.sh"
local wallpaper = "$prefix/scripts/ayame-wallpaper.sh"

hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0
    }
})

hl.on("hyprland.start", function()
    hl.exec_cmd(wallpaper .. " start")
    hl.exec_cmd(ayame .. " --autostart")
end)

hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(ayame .. " ipc call launcher toggle"), { release = true, description = "Open Ayame launcher" })
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"), { description = "Open Kitty terminal" })
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd("kitty"), { description = "Open Kitty terminal (VM fallback)" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Toggle fullscreen" })
hl.bind("SUPER + SHIFT + F", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Close active window" })
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })
for workspace = 1, 5 do
    hl.bind("SUPER + " .. workspace, hl.dsp.focus({ workspace = workspace }), { description = "Focus workspace " .. workspace })
    hl.bind("SUPER + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = workspace }), { description = "Move window to workspace " .. workspace })
end
hl.bind("Print", hl.dsp.exec_cmd(screenshot .. " desktop 0"), { description = "Capture desktop" })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(screenshot .. " area 0"), { description = "Capture area" })
hl.bind("SUPER + Print", hl.dsp.exec_cmd(screenshot .. " monitor 0 ${monitor:-AUTO}"), { description = "Capture monitor" })
EOF

if [[ ! -f "$hypr_main" ]]; then
    if [[ "$assume_yes" == true ]]; then
        link_answer=y
    else
        read -r -p "Create a new Hyprland profile and start Ayame on Hyprland login? [y/N] " link_answer
    fi
    if [[ "$link_answer" =~ ^[Yy]$ ]]; then
        cat > "$hypr_main" <<EOF
-- Created by Ayame Shell for a new Hyprland profile.
dofile("$hypr_fragment")
EOF
        echo "Created $hypr_main and enabled Ayame for Hyprland logins."
    fi
elif ! grep -Fq "dofile(\"$hypr_fragment\")" "$hypr_main"; then
    if [[ "$assume_yes" == true ]]; then
        link_answer=y
    else
        read -r -p "Enable Ayame in $hypr_main now? [y/N] " link_answer
    fi
    if [[ "$link_answer" =~ ^[Yy]$ ]]; then
        cp -a "$hypr_main" "$hypr_main.ayame-backup-$timestamp"
        printf '\n-- Ayame Shell\ndofile("%s")\n' "$hypr_fragment" >> "$hypr_main"
        echo "Backed up Hyprland configuration before adding the Lua loader."
    fi
fi

if [[ -f "$hypr_main" ]]; then
    verification_log="$(mktemp)"
    if Hyprland --verify-config --config "$hypr_main" >"$verification_log" 2>&1; then
        echo "Hyprland configuration validated successfully."
    else
        echo "Warning: Hyprland reported configuration errors:" >&2
        cat "$verification_log" >&2
        echo "Ayame was installed, but review these errors before logging into Hyprland." >&2
    fi
    rm -f "$verification_log"
fi

echo
echo "Ayame Shell is installed."
echo "Run now:  $bin_dir/ayame-shell"
echo "Uninstall: $prefix/uninstall.sh --prefix=$prefix"
echo "Log out and back in after enabling the Hyprland fragment."
if [[ -n "$migration_backup" ]]; then
    echo "Rollback:   $migration_backup/restore.sh"
fi
