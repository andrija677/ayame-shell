pragma Singleton

import QtQuick

QtObject {
    readonly property color surface: "#E61B1B26"
    readonly property color surfaceRaised: "#FF292936"
    readonly property color textPrimary: "#FFF4F2FA"
    readonly property color textMuted: "#FFAAA7B5"
    readonly property color accent: "#FFA78BFA"

    readonly property int barHeight: 42
    readonly property int outerMargin: 8
    readonly property int itemHeight: 28
    readonly property int itemRadius: 9
    readonly property int itemSpacing: 6
    readonly property int horizontalPadding: 10

    readonly property int fontSmall: 12
    readonly property int fontNormal: 13
    readonly property int animationFast: 140
}

