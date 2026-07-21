import QtQuick
import Quickshell
import "../settings"
import "../theme"

Surface {
    id: root

    property bool expanded: false
    signal activated()

    implicitWidth: (expanded ? dateText.implicitWidth : timeText.implicitWidth)
        + Theme.space24
    implicitHeight: Theme.itemHeight
    radius: Theme.radiusPill
    color: pointer.containsMouse
        ? Theme.primaryContainer
        : Theme.surfaceContainerHigh
    scale: pointer.pressed ? 0.96 : 1

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.motionNormal
            easing.type: Theme.easeEnter
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionFast
            easing.type: Theme.easeEnter
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    StyledText {
        id: timeText
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date,
            ShellConfig.clockFormat === "12h" ? "h:mm AP" : "HH:mm")
        font.family: Theme.fontFamily
        color: Theme.foregroundSurface
        opacity: root.expanded ? 0 : 1
        y: root.expanded ? Theme.space4 : 0
        scale: root.expanded ? 0.92 : 1
        font.pixelSize: Theme.fontNormal
        font.weight: Theme.fontWeightLabel

        Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
        Behavior on y { NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter } }
        Behavior on scale { NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter } }
    }

    StyledText {
        id: dateText
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd, d MMM  •  "
            + (ShellConfig.clockFormat === "12h" ? "h:mm AP" : "HH:mm"))
        color: Theme.foregroundPrimaryContainer
        opacity: root.expanded ? 1 : 0
        y: root.expanded ? 0 : -Theme.space4
        scale: root.expanded ? 1 : 0.92
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontNormal
        font.weight: Theme.fontWeightLabel

        Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
        Behavior on y { NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter } }
        Behavior on scale { NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter } }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.activated()
    }
}
