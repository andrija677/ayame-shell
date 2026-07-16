#!/usr/bin/env bash
set -euo pipefail

mode="${1:-dark}"
case "$mode" in
    light)
        kde_scheme="BreezeLight"
        gnome_scheme="default"
        qt_palette="airy.conf"
        icon_theme="breeze"
        ;;
    dark)
        kde_scheme="BreezeDark"
        gnome_scheme="prefer-dark"
        qt_palette="darker.conf"
        icon_theme="breeze-dark"
        ;;
    *)
        printf 'Unknown appearance mode: %s\n' "$mode" >&2
        exit 2
        ;;
esac

# KDE applications such as Dolphin read their colors from kdeglobals. Write the
# complete scheme directly as well as asking Plasma to apply it: the Plasma
# helper may be present but ineffective when Ayame is running under Hyprland.
kde_writer=""
if command -v kwriteconfig6 >/dev/null 2>&1; then
    kde_writer="kwriteconfig6"
elif command -v kwriteconfig5 >/dev/null 2>&1; then
    kde_writer="kwriteconfig5"
fi
kde_scheme_file="/usr/share/color-schemes/${kde_scheme}.colors"
kde_globals="${XDG_CONFIG_HOME:-$HOME/.config}/kdeglobals"
if [[ -n "$kde_writer" && -f "$kde_scheme_file" ]]; then
    while IFS=$'\t' read -r group key value; do
        [[ -n "$group" && -n "$key" ]] || continue
        "$kde_writer" --file "$kde_globals" --group "$group" \
            --key "$key" "$value" || true
    done < <(awk '
        /^\[[^]]+\]$/ { group = substr($0, 2, length($0) - 2); next }
        /^[[:space:]]*($|#)/ { next }
        index($0, "=") > 0 {
            key = substr($0, 1, index($0, "=") - 1)
            value = substr($0, index($0, "=") + 1)
            print group "\t" key "\t" value
        }
    ' "$kde_scheme_file")
fi
if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    timeout 4s plasma-apply-colorscheme "$kde_scheme" >/dev/null 2>&1 || true
fi

# GTK 4/libadwaita applications, including GNOME Files, follow this preference.
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme "$gnome_scheme" || true
fi

# Generic Qt applications may use qt5ct/qt6ct instead of KDE's palette. Keep
# those selectors in the same mode when an existing qtct setup is present.
if [[ -n "$kde_writer" ]]; then
    for generation in 5 6; do
        config="${XDG_CONFIG_HOME:-$HOME/.config}/qt${generation}ct/qt${generation}ct.conf"
        palette="/usr/share/qt${generation}ct/colors/$qt_palette"
        [[ -f "$config" && -f "$palette" ]] || continue
        "$kde_writer" --file "$config" --group Appearance \
            --key color_scheme_path "$palette" || true
        "$kde_writer" --file "$config" --group Appearance \
            --key custom_palette true || true
        "$kde_writer" --file "$config" --group Appearance \
            --key icon_theme "$icon_theme" || true
    done
fi
