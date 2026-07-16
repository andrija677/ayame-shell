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

# KDE applications such as Dolphin read their colors from kdeglobals. Plasma's
# helper updates every color group together, avoiding mixed light/dark text.
if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    plasma-apply-colorscheme "$kde_scheme" >/dev/null || true
fi

# GTK 4/libadwaita applications, including GNOME Files, follow this preference.
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme "$gnome_scheme" || true
fi

# Generic Qt applications may use qt5ct/qt6ct instead of KDE's palette. Keep
# those selectors in the same mode when an existing qtct setup is present.
if command -v kwriteconfig6 >/dev/null 2>&1; then
    for generation in 5 6; do
        config="${XDG_CONFIG_HOME:-$HOME/.config}/qt${generation}ct/qt${generation}ct.conf"
        palette="/usr/share/qt${generation}ct/colors/$qt_palette"
        [[ -f "$config" && -f "$palette" ]] || continue
        kwriteconfig6 --file "$config" --group Appearance \
            --key color_scheme_path "$palette" || true
        kwriteconfig6 --file "$config" --group Appearance \
            --key custom_palette true || true
        kwriteconfig6 --file "$config" --group Appearance \
            --key icon_theme "$icon_theme" || true
    done
fi
