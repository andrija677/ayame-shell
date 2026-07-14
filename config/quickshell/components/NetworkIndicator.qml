import QtQuick
import Quickshell.Networking
import "../theme"

Rectangle {
    id: root

    readonly property var connectedWifi: {
        const devices = Networking.devices.values;
        for (let device of devices) {
            if (device.type !== DeviceType.Wifi)
                continue;

            const networks = device.networks.values;
            for (let network of networks) {
                if (network.connected)
                    return network;
            }
        }
        return null;
    }
    readonly property bool online: Networking.connectivity
        === NetworkConnectivity.Full
    readonly property bool limited: Networking.connectivity
        === NetworkConnectivity.Limited
        || Networking.connectivity === NetworkConnectivity.Portal
    readonly property int signalPercent: Math.round(
        connectedWifi?.signalStrength ?? 0
    )

    implicitWidth: label.implicitWidth + Theme.space16
    implicitHeight: Theme.itemHeight
    radius: Theme.radiusPill
    color: "transparent"

    StyledText {
        id: label
        anchors.centerIn: parent
        text: root.connectedWifi
            ? "WIFI " + root.signalPercent + "%"
            : root.online ? "NET"
            : root.limited ? "LIMITED"
            : "OFFLINE"
        color: root.online ? Theme.foregroundSurfaceVariant
            : root.limited ? Theme.warning
            : Theme.error
        font.pixelSize: Theme.fontSmall
        font.weight: Font.DemiBold

        Behavior on color {
            ColorAnimation { duration: Theme.motionNormal }
        }
    }
}
