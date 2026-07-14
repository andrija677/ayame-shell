pragma Singleton

import QtQuick
import "../settings"
import "../services"

QtObject {
    readonly property bool compact: ShellConfig.densityMode === "compact"

    // Semantic colors: components describe a color's purpose, not its shade.
    // A generated wallpaper palette can replace these values later.
    readonly property color background: DynamicPalette.active
        ? DynamicPalette.darkColor("background", "#121116") : "#FF121116"
    readonly property color surface: DynamicPalette.active
        ? DynamicPalette.darkColor("surface", "#1C1B22") : "#F21C1B22"
    readonly property color surfaceContainer: DynamicPalette.active
        ? DynamicPalette.darkColor("surface_container", "#25232C") : "#FF25232C"
    readonly property color surfaceContainerHigh: DynamicPalette.active
        ? DynamicPalette.darkColor("surface_container_high", "#302D39") : "#FF302D39"
    readonly property color foregroundSurface: DynamicPalette.active
        ? DynamicPalette.darkColor("on_surface", "#F0ECF4") : "#FFF0ECF4"
    readonly property color foregroundSurfaceVariant: DynamicPalette.active
        ? DynamicPalette.darkColor("on_surface_variant", "#C9C3CE") : "#FFC9C3CE"
    readonly property color outline: DynamicPalette.active
        ? DynamicPalette.darkColor("outline", "#958E9B") : "#FF958E9B"
    readonly property color outlineVariant: DynamicPalette.active
        ? DynamicPalette.darkColor("outline_variant", "#49454F") : "#FF49454F"

    readonly property color primary: DynamicPalette.active
        ? DynamicPalette.darkColor("primary", "#D0BCFF") : "#FFD0BCFF"
    readonly property color foregroundPrimary: DynamicPalette.active
        ? DynamicPalette.darkColor("on_primary", "#381E72") : "#FF381E72"
    readonly property color primaryContainer: DynamicPalette.active
        ? DynamicPalette.darkColor("primary_container", "#4F378B") : "#FF4F378B"
    readonly property color foregroundPrimaryContainer: DynamicPalette.active
        ? DynamicPalette.darkColor("on_primary_container", "#EADDFF") : "#FFEADDFF"

    readonly property color success: "#FFA6D6A8"
    readonly property color warning: "#FFFFDDB3"
    readonly property color error: "#FFFFB4AB"

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
