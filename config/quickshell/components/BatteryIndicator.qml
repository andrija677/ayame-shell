import QtQuick
import Quickshell.Services.UPower
import "../theme"

Rectangle {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool available: battery?.isPresent
        && battery?.isLaptopBattery
    readonly property int percentage: Math.round(battery?.percentage ?? 0)
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
        || battery?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: battery?.state === UPowerDeviceState.FullyCharged

    visible: available
    implicitWidth: visible ? label.implicitWidth + Theme.space16 : 0
    implicitHeight: Theme.itemHeight
    radius: Theme.radiusPill
    color: "transparent"

    StyledText {
        id: label
        anchors.centerIn: parent
        text: (root.charging ? "+" : "") + root.percentage + "%"
        color: root.charging || root.full ? Theme.success
            : root.percentage <= 10 ? Theme.error
            : root.percentage <= 20 ? Theme.warning
            : Theme.foregroundSurfaceVariant
        font.pixelSize: Theme.fontSmall
        font.weight: Font.DemiBold

        Behavior on color {
            ColorAnimation { duration: Theme.motionNormal }
        }
    }
}
