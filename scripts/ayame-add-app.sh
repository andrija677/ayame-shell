#!/usr/bin/env bash
set -euo pipefail

executable="${1:-}"
[[ -n "$executable" ]] || { printf 'No executable was selected.\n' >&2; exit 2; }
[[ -f "$executable" ]] || { printf 'The selected file no longer exists.\n' >&2; exit 2; }

executable="$(realpath "$executable")"
chmod u+x "$executable"
[[ -x "$executable" ]] || { printf 'The selected file is not executable.\n' >&2; exit 2; }

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
applications_dir="$data_home/applications"
icons_dir="$data_home/icons/hicolor/256x256/apps"
mkdir -p "$applications_dir" "$icons_dir"

base_name="$(basename "$executable")"
display_name="${base_name%.[Aa][Pp][Pp][Ii][Mm][Aa][Gg][Ee]}"
display_name="${display_name//-/ }"
desktop_id="ayame-app-$(printf '%s' "$executable" | sha256sum | cut -c1-16)"
desktop_file="$applications_dir/$desktop_id.desktop"
icon_name="application-x-executable"

# AppImages normally contain their own desktop metadata and icon. Extract them
# only to improve presentation; every other executable uses a system icon.
case "${executable,,}" in
    *.appimage)
        temp_dir="$(mktemp -d)"
        trap 'rm -rf -- "$temp_dir"' EXIT
        if (cd "$temp_dir" && "$executable" --appimage-extract >/dev/null 2>&1); then
            embedded_desktop="$(find "$temp_dir/squashfs-root" -maxdepth 2 -type f -name '*.desktop' -print -quit 2>/dev/null || true)"
            if [[ -n "$embedded_desktop" ]]; then
                embedded_name="$(sed -n 's/^Name=//p' "$embedded_desktop" | head -n 1)"
                [[ -n "$embedded_name" ]] && display_name="$embedded_name"
                embedded_icon="$(sed -n 's/^Icon=//p' "$embedded_desktop" | head -n 1)"
                if [[ -n "$embedded_icon" ]]; then
                    icon_file="$(find "$temp_dir/squashfs-root" -type f \
                        \( -iname "$embedded_icon.png" -o -iname "$embedded_icon.svg" \
                           -o -iname "$embedded_icon.xpm" -o -iname '.DirIcon' \) \
                        -print -quit 2>/dev/null || true)"
                    if [[ -n "$icon_file" ]]; then
                        icon_extension="${icon_file##*.}"
                        [[ "$icon_file" == */.DirIcon ]] && icon_extension="png"
                        icon_target="$icons_dir/$desktop_id.$icon_extension"
                        cp -- "$icon_file" "$icon_target"
                        icon_name="$icon_target"
                    fi
                fi
            fi
        fi
        ;;
esac

escape_desktop_value() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//$'\n'/ }"
    value="${value//;/\\;}"
    printf '%s' "$value"
}

escaped_name="$(escape_desktop_value "$display_name")"
escaped_exec="${executable//\\/\\\\}"
escaped_exec="${escaped_exec//\"/\\\"}"

desktop_temp="$desktop_file.tmp"
printf '%s\n' \
    '[Desktop Entry]' \
    'Type=Application' \
    "Name=$escaped_name" \
    'Comment=Application registered by Ayame Shell' \
    "Exec=\"$escaped_exec\" %U" \
    "Icon=$icon_name" \
    'Terminal=false' \
    'Categories=Utility;' \
    'StartupNotify=true' \
    > "$desktop_temp"
chmod 644 "$desktop_temp"
mv -f -- "$desktop_temp" "$desktop_file"

command -v update-desktop-database >/dev/null 2>&1 \
    && update-desktop-database "$applications_dir" >/dev/null 2>&1 || true

printf '%s\n' "$display_name"
