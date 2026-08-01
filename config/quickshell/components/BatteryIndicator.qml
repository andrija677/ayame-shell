import QtQuick
import Quickshell.Services.UPower
import "../theme"

Rectangle {
    id: root

    signal activated()
    readonly property var battery: UPower.displayDevice
    readonly property bool available: battery?.isPresent
        && battery?.isLaptopBattery
    readonly property int percentage: Math.round(
        Math.max(0, Math.min(1, battery?.percentage ?? 0)) * 100)
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
        || battery?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: battery?.state === UPowerDeviceState.FullyCharged

    visible: available
    implicitWidth: visible ? label.implicitWidth + Theme.space16 : 0
    implicitHeight: Theme.itemHeight
    radius: Theme.radiusPill
    color: pointer.containsMouse ? Theme.surfaceContainerHigh : "transparent"
    scale: pointer.pressed ? 0.94 : 1

    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    Behavior on scale {
        NumberAnimation { duration: Theme.motionFast; easing.type: Theme.easeEnter }
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        text: (root.charging ? "+" : "") + root.percentage + "%"
        font.family: Theme.fontFamilyNumeric
        color: root.charging || root.full ? Theme.success
            : root.percentage <= 10 ? Theme.error
            : root.percentage <= 20 ? Theme.warning
            : Theme.foregroundSurfaceVariant
        font.pixelSize: Theme.fontSmall
        font.weight: Theme.fontWeightLabel

        Behavior on color {
            ColorAnimation { duration: Theme.motionNormal }
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
