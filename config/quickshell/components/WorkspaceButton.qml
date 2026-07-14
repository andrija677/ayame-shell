import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    required property int workspaceId
    required property bool active
    signal activated()

    readonly property bool hovered: pointer.containsMouse
    readonly property bool pressed: pointer.pressed

    implicitWidth: active ? 32 : 24
    implicitHeight: Theme.itemHeight
    radius: Theme.radiusPill
    color: active
        ? Theme.primary
        : hovered ? Theme.surfaceContainerHigh : "transparent"
    scale: pressed ? 0.92 : 1

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.motionNormal
            easing.type: Theme.easeEnter
        }
    }

    Behavior on color {
        ColorAnimation { duration: Theme.motionFast }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionFast
            easing.type: Theme.easeEnter
        }
    }

    StyledText {
        anchors.centerIn: parent
        text: root.workspaceId
        font.family: Theme.fontFamilyNumeric
        color: root.active
            ? Theme.foregroundPrimary
            : Theme.foregroundSurfaceVariant
        font.pixelSize: Theme.fontSmall
        font.weight: root.active ? Theme.fontWeightLabel : Theme.fontWeightBody

        Behavior on color {
            ColorAnimation { duration: Theme.motionFast }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
