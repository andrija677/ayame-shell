pragma Singleton

import QtQuick
import "../settings"
import "../services"

QtObject {
    readonly property bool compact: ShellConfig.densityMode === "compact"
    readonly property bool lightMode: ShellConfig.colorScheme === "light"

    function palette(name, darkFallback, lightFallback) {
        const fallback = lightMode ? lightFallback : darkFallback;
        return DynamicPalette.active
            ? DynamicPalette.modeColor(name, lightMode ? "light" : "dark", fallback)
            : fallback;
    }

    function blend(base, tint, amount) {
        return Qt.rgba(
            base.r * (1 - amount) + tint.r * amount,
            base.g * (1 - amount) + tint.g * amount,
            base.b * (1 - amount) + tint.b * amount,
            base.a
        );
    }

    function translucent(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    // Semantic colors: components describe a color's purpose, not its shade.
    // A generated wallpaper palette can replace these values later.
    readonly property color primary: palette("primary", "#D0BCFF", "#68548E")
    readonly property color foregroundPrimary: palette("on_primary", "#381E72", "#FFFFFF")
    readonly property color primaryContainer: palette("primary_container", "#4F378B", "#EBDDFF")
    readonly property color foregroundPrimaryContainer: palette("on_primary_container", "#EADDFF", "#230F46")

    readonly property color background: palette("background", "#121116", "#FEF7FF")
    readonly property color baseSurface: palette("surface", "#1C1B22", "#FEF7FF")
    readonly property color baseSurfaceContainer: palette("surface_container", "#25232C", "#F2ECF4")
    readonly property color baseSurfaceContainerHigh: palette("surface_container_high", "#302D39", "#EDE6EE")
    readonly property real surfaceTintAmount: DynamicPalette.active
        && ShellConfig.wallpaperTintEnabled ? (lightMode ? 0.08 : 0.14) : 0
    readonly property color surface: translucent(
        blend(baseSurface, primary, surfaceTintAmount),
        ShellConfig.blurEnabled ? (lightMode ? 0.78 : 0.72) : 0.95
    )
    readonly property color surfaceContainer: translucent(
        blend(baseSurfaceContainer, primary, surfaceTintAmount),
        ShellConfig.blurEnabled ? (lightMode ? 0.72 : 0.68) : 1
    )
    readonly property color surfaceContainerHigh: translucent(
        blend(baseSurfaceContainerHigh, primary, surfaceTintAmount),
        ShellConfig.blurEnabled ? (lightMode ? 0.78 : 0.74) : 1
    )
    readonly property color foregroundSurface: palette("on_surface", "#F0ECF4", "#1D1B20")
    readonly property color foregroundSurfaceVariant: palette("on_surface_variant", "#C9C3CE", "#49454E")
    readonly property color outline: palette("outline", "#958E9B", "#7A757F")
    readonly property color outlineVariant: palette("outline_variant", "#49454F", "#CBC4CF")

    readonly property color success: lightMode ? "#386A3A" : "#A6D6A8"
    readonly property color warning: lightMode ? "#765A00" : "#FFDDB3"
    readonly property color error: palette("error", "#FFB4AB", "#BA1A1A")

    readonly property int barHeight: compact ? 38 : 42
    readonly property int dockHeight: compact ? 46 : 50
    readonly property int outerMargin: compact ? 6 : 8
    readonly property int itemHeight: compact ? 26 : 28
    readonly property int sideAreaWidth: compact ? 220 : 240

    readonly property int space2: 2
    readonly property int space4: 4
    readonly property int space6: 6
    readonly property int space8: 8
    readonly property int space12: compact ? 10 : 12
    readonly property int space16: compact ? 14 : 16
    readonly property int space24: compact ? 20 : 24

    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: compact ? 14 : 16
    readonly property int radiusPill: 999

    readonly property int fontSmall: 12
    readonly property int fontNormal: 13
    readonly property int fontTitle: 15
    readonly property string fontFamily: "Fira Sans"
    readonly property string fontFamilyNumeric: "JetBrainsMono Nerd Font"
    readonly property int fontWeightBody: Font.Medium
    readonly property int fontWeightLabel: Font.DemiBold
    readonly property int fontWeightTitle: Font.Bold
    readonly property int fontWeightDisplay: Font.ExtraBold

    // Motion is deliberately asymmetric: interactions react quickly, while
    // larger surfaces get enough time to settle into place without snapping.
    readonly property int motionFast: ShellConfig.animationsEnabled ? 140 : 0
    readonly property int motionNormal: ShellConfig.animationsEnabled ? 250 : 0
    readonly property int motionSlow: ShellConfig.animationsEnabled ? 400 : 0
    readonly property int easeEnter: Easing.OutQuint
    readonly property int easeExit: Easing.InQuart
}
