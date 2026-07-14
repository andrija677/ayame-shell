pragma Singleton

import QtQuick

QtObject {
    // Semantic colors: components describe a color's purpose, not its shade.
    // A generated wallpaper palette can replace these values later.
    readonly property color background: "#FF121116"
    readonly property color surface: "#F21C1B22"
    readonly property color surfaceContainer: "#FF25232C"
    readonly property color surfaceContainerHigh: "#FF302D39"
    readonly property color foregroundSurface: "#FFF0ECF4"
    readonly property color foregroundSurfaceVariant: "#FFC9C3CE"
    readonly property color outline: "#FF958E9B"
    readonly property color outlineVariant: "#FF49454F"

    readonly property color primary: "#FFD0BCFF"
    readonly property color foregroundPrimary: "#FF381E72"
    readonly property color primaryContainer: "#FF4F378B"
    readonly property color foregroundPrimaryContainer: "#FFEADDFF"

    readonly property color success: "#FFA6D6A8"
    readonly property color warning: "#FFFFDDB3"
    readonly property color error: "#FFFFB4AB"

    readonly property int barHeight: 42
    readonly property int outerMargin: 8
    readonly property int itemHeight: 28
    readonly property int sideAreaWidth: 240

    readonly property int space2: 2
    readonly property int space4: 4
    readonly property int space6: 6
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space24: 24

    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 16
    readonly property int radiusPill: 999

    readonly property int fontSmall: 12
    readonly property int fontNormal: 13
    readonly property int fontTitle: 15
    readonly property string fontFamily: "Noto Sans"

    readonly property int motionFast: 120
    readonly property int motionNormal: 220
    readonly property int motionSlow: 360
}
