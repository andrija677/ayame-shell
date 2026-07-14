import QtQuick
import Quickshell
import "../theme"

Surface {
    id: root

    property bool expanded: false
    signal activated()

    implicitWidth: clockText.implicitWidth + Theme.space24
    implicitHeight: Theme.itemHeight
    radius: Theme.radiusPill
    color: pointer.containsMouse
        ? Theme.primaryContainer
        : Theme.surfaceContainerHigh
    scale: pointer.pressed ? 0.96 : 1

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.motionNormal
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionFast
            easing.type: Easing.OutCubic
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    StyledText {
        id: clockText
        anchors.centerIn: parent
        text: root.expanded
            ? Qt.formatDateTime(clock.date, "ddd, d MMM  •  HH:mm")
            : Qt.formatDateTime(clock.date, "HH:mm")
        color: root.expanded
            ? Theme.foregroundPrimaryContainer
            : Theme.foregroundSurface
        font.pixelSize: Theme.fontNormal
        font.weight: Font.DemiBold

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
