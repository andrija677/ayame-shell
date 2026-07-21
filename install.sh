#!/usr/bin/env bash
set -euo pipefail

prefix="${XDG_DATA_HOME:-$HOME/.local/share}/ayame-shell"
assume_yes=false
install_dependencies=true
replace_desktop=false
enable_kitty=true
update_only=false
check_only=false
for argument in "$@"; do
    case "$argument" in
        --yes) assume_yes=true ;;
        --no-install-deps) install_dependencies=false ;;
        --replace-desktop) replace_desktop=true ;;
        --update) assume_yes=true; install_dependencies=false; update_only=true ;;
        --check) check_only=true; install_dependencies=false ;;
        --no-kitty) enable_kitty=false ;;
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
user_systemd_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
shell_service="$user_systemd_dir/ayame-shell.service"
timestamp="$(date +%Y%m%d-%H%M%S)"
migration_backup=""
sudoers_file="/etc/sudoers.d/ayame-hyprshutdown-${USER}"

os_id="unknown"
os_name="Unknown Linux"
os_version="unknown"
os_codename="unknown"
os_like=""
if [[ -r /etc/os-release ]]; then
    # The file is defined as shell-compatible KEY=VALUE data by os-release(5).
    source /etc/os-release
    os_id="${ID:-unknown}"
    os_name="${PRETTY_NAME:-${NAME:-Unknown Linux}}"
    os_version="${VERSION_ID:-unknown}"
    os_codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-unknown}}"
    os_like="${ID_LIKE:-}"
fi

package_family=unknown
case " $os_id $os_like " in
    *" arch "*) package_family=arch ;;
    *" debian "*|*" ubuntu "*) package_family=debian ;;
esac

required=(qs hyprctl hyprlock hyprpaper grim slurp wf-recorder wl-copy kitty \
    matugen rofi rofimoji curl pw-dump nmcli notify-send python3)

hyprland_version="missing"
hyprland_compatible=false
if command -v Hyprland >/dev/null 2>&1; then
    hyprland_version_output="$(Hyprland --version 2>/dev/null | head -n 1 || true)"
    if [[ "$hyprland_version_output" =~ Hyprland[[:space:]]+([0-9]+)\.([0-9]+) ]]; then
        hyprland_version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
        if ((BASH_REMATCH[1] > 0 || BASH_REMATCH[2] >= 55)); then
            hyprland_compatible=true
        fi
    fi
fi
declare -A command_packages=(
    [qs]=quickshell
    [hyprctl]=hyprland
    [hyprlock]=hyprlock
    [hyprpaper]=hyprpaper
    [grim]=grim
    [slurp]=slurp
    [wf-recorder]=wf-recorder
    [wl-copy]=wl-clipboard
    [kitty]=kitty
    [matugen]=matugen
    [rofi]=rofi
    [rofimoji]=rofimoji
    [curl]=curl
    [pw-dump]=pipewire
    [nmcli]=networkmanager
    [notify-send]=libnotify
    [python3]=python
)
if [[ "$package_family" == debian ]]; then
    command_packages[qs]=quickshell
    command_packages[hyprctl]=hyprland
    command_packages[hyprlock]=hyprlock
    command_packages[hyprpaper]=hyprpaper
    command_packages[grim]=grim
    command_packages[slurp]=slurp
    command_packages[wf-recorder]=wf-recorder
    command_packages[wl-copy]=wl-clipboard
    command_packages[kitty]=kitty
    command_packages[matugen]=matugen
    command_packages[rofi]=rofi
    command_packages[rofimoji]=rofimoji
    command_packages[curl]=curl
    command_packages[pw-dump]=pipewire-bin
    command_packages[nmcli]=network-manager
    command_packages[notify-send]=libnotify-bin
    command_packages[python3]=python3
fi
missing=()
for command_name in "${required[@]}"; do
    command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
done

if [[ "$check_only" == true ]]; then
    echo "Ayame Shell compatibility check"
    echo "  System:      $os_name"
    echo "  ID:          $os_id $os_version"
    echo "  Base:        $os_like"
    echo "  Codename:    $os_codename"
    echo "  Packages:    $package_family"
    echo "  Hyprland:    $hyprland_version (Ayame requires 0.55+)"
    if ((${#missing[@]} == 0)); then
        echo "  Commands:    all Ayame runtime commands are present"
        [[ "$hyprland_compatible" == true ]] \
            || echo "  Compatibility: Hyprland is too old for Ayame's Lua profile"
        exit 0
    fi
    printf '  Missing:     %s\n' "${missing[*]}"
    if [[ "$package_family" == debian ]]; then
        echo "  Repository package check:"
        for command_name in "${missing[@]}"; do
            package_name="${command_packages[$command_name]}"
            if apt-cache show "$package_name" >/dev/null 2>&1; then
                printf '    %-14s %-22s available\n' "$command_name" "$package_name"
            else
                printf '    %-14s %-22s UNAVAILABLE\n' "$command_name" "$package_name"
            fi
        done
        echo "Run 'sudo apt update' first if the package lists are stale."
    elif [[ "$package_family" == arch ]]; then
        echo "  Repository packages: ${missing[*]}"
    else
        echo "  Automatic dependency installation is not available for this system."
    fi
    exit 0
fi

if ((${#missing[@]})); then
    printf 'Missing required commands: %s\n' "${missing[*]}"
    missing_packages=()
    for command_name in "${missing[@]}"; do
        package_name="${command_packages[$command_name]}"
        [[ " ${missing_packages[*]} " == *" $package_name "* ]] \
            || missing_packages+=("$package_name")
    done
    printf 'Packages needed: %s\n' "${missing_packages[*]}"

    if [[ "$update_only" == true ]]; then
        echo "Continuing the update without optional missing dependencies."
        if [[ "$package_family" == arch ]]; then
            echo "Install later with: sudo pacman -S ${missing_packages[*]}"
        elif [[ "$package_family" == debian ]]; then
            echo "Install later with: sudo apt install ${missing_packages[*]}"
        fi
    else
    if [[ "$install_dependencies" != true ]]; then
        echo "Dependency installation was disabled with --no-install-deps." >&2
        exit 1
    fi
    if [[ "$package_family" == unknown ]]; then
        echo "Automatic dependency installation does not support $os_name yet." >&2
        echo "Install the commands listed above, then rerun with --no-install-deps." >&2
        exit 1
    fi
    if [[ "$assume_yes" == true ]]; then
        dependency_answer=y
    else
        read -r -p "Install the missing packages for $os_name now? [y/N] " dependency_answer
    fi
    if [[ ! "$dependency_answer" =~ ^[Yy]$ ]]; then
        echo "Install the listed packages, then run this installer again." >&2
        exit 1
    fi
    if [[ "$package_family" == arch ]]; then
        sudo pacman -S --needed "${missing_packages[@]}"
    else
        sudo apt-get update
        unavailable_packages=()
        for package_name in "${missing_packages[@]}"; do
            apt-cache show "$package_name" >/dev/null 2>&1 \
                || unavailable_packages+=("$package_name")
        done
        if ((${#unavailable_packages[@]})); then
            printf 'Unavailable in %s (%s) repositories: %s\n' \
                "$os_name" "$os_codename" "${unavailable_packages[*]}" >&2
            echo "Ayame will not add third-party repositories or mix incompatible releases automatically." >&2
            echo "Install a compatible Hyprland/Quickshell stack from a trusted source, then rerun this installer." >&2
            exit 1
        fi
        sudo apt-get install -y "${missing_packages[@]}"
    fi

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
fi

# Re-read the version after dependency installation as the package manager may
# have installed or upgraded Hyprland during this run.
hyprland_version_output="$(Hyprland --version 2>/dev/null | head -n 1 || true)"
hyprland_compatible=false
if [[ "$hyprland_version_output" =~ Hyprland[[:space:]]+([0-9]+)\.([0-9]+) ]] \
        && ((BASH_REMATCH[1] > 0 || BASH_REMATCH[2] >= 55)); then
    hyprland_compatible=true
fi
if [[ "$hyprland_compatible" != true ]]; then
    echo "Ayame requires Hyprland 0.55 or newer for its Lua configuration." >&2
    echo "Detected: ${hyprland_version_output:-unknown version}" >&2
    exit 1
fi

if [[ "$update_only" != true ]] \
        && command -v pacman >/dev/null 2>&1 \
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
echo "  System:      $os_name ($os_id $os_version; $os_codename)"
echo "  Packages:    $package_family"
echo "  Source:      $source_dir"
echo "  Destination: $prefix"
echo "  Launcher:    $bin_dir/ayame-shell"
echo "  Hyprland:    $hypr_fragment"
if [[ "$assume_yes" != true ]]; then
    read -r -p "Continue? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 0
fi

if [[ "$update_only" != true && -f "$sudoers_file" ]]; then
    echo "Removing Ayame's obsolete VT handoff rule."
    sudo rm -f "$sudoers_file"
fi

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

mkdir -p "$(dirname -- "$prefix")" "$bin_dir" "$hypr_dir" "$kitty_dir" \
    "$user_systemd_dir"
if [[ -e "$prefix" ]]; then
    backup="${prefix}.backup-${timestamp}"
    echo "Backing up the previous Ayame installation to $backup"
    mv -- "$prefix" "$backup"
fi

mkdir -p "$prefix"
cp -a "$source_dir/assets" "$source_dir/config" "$source_dir/docs" \
    "$source_dir/scripts" "$source_dir/themes" "$source_dir/README.md" \
    "$source_dir/bootstrap.sh" "$source_dir/install.sh" \
    "$source_dir/uninstall.sh" "$prefix/"
chmod +x "$prefix/scripts/ayame-screenshot.sh" \
    "$prefix/scripts/ayame-record.sh" \
    "$prefix/scripts/ayame-gaming-mode.sh" \
    "$prefix/scripts/ayame-appearance-mode.sh" \
    "$prefix/scripts/ayame-update.sh" \
    "$prefix/scripts/ayame-kitty-colors.sh" \
    "$prefix/scripts/ayame-wallpaper.sh" \
    "$prefix/scripts/ayame-emoji-picker.sh" \
    "$prefix/scripts/ayame-logout.sh" \
    "$prefix/scripts/ayame-session-takeover.sh" \
    "$prefix/scripts/ayame-run-command.sh" "$prefix/uninstall.sh"
chmod +x "$prefix/bootstrap.sh" "$prefix/install.sh"

if [[ "$replace_desktop" == true ]]; then
    "$prefix/scripts/ayame-session-takeover.sh" apply
fi

lock_wallpaper="$prefix/assets/wallpapers/ayame-default.jpg"
wallpaper_state="${XDG_STATE_HOME:-$HOME/.local/state}/ayame-shell/wallpaper.path"
if [[ -f "$wallpaper_state" ]]; then
    saved_wallpaper="$(head -n 1 "$wallpaper_state")"
    [[ -f "$saved_wallpaper" ]] && lock_wallpaper="$saved_wallpaper"
fi
lock_config="$prefix/config/hyprlock/hyprlock.conf"
temporary_lock="$(mktemp)"
awk -v wallpaper="$lock_wallpaper" \
    '$0 ~ /^\$wallpaper = / { print "$wallpaper = " wallpaper; next } { print }' \
    "$lock_config" >"$temporary_lock"
install -m 0644 "$temporary_lock" "$lock_config"
rm -f "$temporary_lock"

if [[ "$enable_kitty" == true ]]; then
    install -m 0644 "$prefix/config/kitty/ayame-shell.conf" "$kitty_fragment"
    # This file is generated live from Ayame's current light/dark wallpaper
    # palette. Preserve it during updates instead of flashing back to the
    # repository's default dark colors; create the default only once.
    if [[ ! -f "$kitty_dir/ayame-colors.conf" ]]; then
        install -m 0644 "$prefix/config/kitty/ayame-colors.conf" \
            "$kitty_dir/ayame-colors.conf"
    fi
    if ! grep -Fq "include $kitty_fragment" "$kitty_main" 2>/dev/null; then
        if [[ -f "$kitty_main" ]]; then
            cp -a "$kitty_main" "$kitty_main.ayame-backup-$timestamp"
            printf '\n# Ayame Shell\ninclude %s\n' "$kitty_fragment" >> "$kitty_main"
        else
            printf '# Created by Ayame Shell.\ninclude %s\n' "$kitty_fragment" > "$kitty_main"
        fi
        echo "Enabled the Ayame Kitty design and dynamic colors."
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

cat > "$shell_service" <<EOF
[Unit]
Description=Ayame Shell
After=graphical-session.target pipewire.service

[Service]
Type=simple
ExecStart=$bin_dir/ayame-shell --autostart
Restart=on-failure
RestartSec=2
TimeoutStopSec=5

[Install]
WantedBy=graphical-session.target
EOF
systemctl --user daemon-reload

monitor="$(hyprctl monitors 2>/dev/null | awk '/^Monitor / {print $2; exit}' || true)"
cat > "$hypr_fragment" <<EOF
-- Generated by Ayame Shell. Edit or remove safely.
local ayame = "$bin_dir/ayame-shell"
local screenshot = "$prefix/scripts/ayame-screenshot.sh"
local recorder = "$prefix/scripts/ayame-record.sh"
local wallpaper = "$prefix/scripts/ayame-wallpaper.sh"
local emoji_picker = "$prefix/scripts/ayame-emoji-picker.sh"
local lock_config = "$prefix/config/hyprlock/hyprlock.conf"

hl.config({
    decoration = {
        rounding = 14,
        rounding_power = 2
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0
    }
})

hl.on("hyprland.start", function()
    hl.exec_cmd(wallpaper .. " start")
    hl.exec_cmd("systemctl --user start ayame-shell.service")
end)

hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(ayame .. " ipc call launcher toggle"), { release = true, description = "Open Ayame launcher" })
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"), { description = "Open Kitty terminal" })
hl.bind("SUPER + PERIOD", hl.dsp.exec_cmd(emoji_picker), { description = "Open emoji picker" })
hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock --config " .. lock_config), { description = "Lock with Ayame" })
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
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(ayame .. " ipc call capture area || " .. screenshot .. " area 0"), { description = "Capture area" })
hl.bind("SUPER + Print", hl.dsp.exec_cmd(screenshot .. " monitor 0 ${monitor:-AUTO}"), { description = "Capture monitor" })
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd(recorder .. " toggle desktop none AUTO 0"), { description = "Toggle screen recording" })
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
