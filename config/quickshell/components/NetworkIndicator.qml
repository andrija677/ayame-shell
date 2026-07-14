import QtQuick
import Quickshell
import Quickshell.Networking
import "../theme"

Rectangle {
    id: root

    required property var hostWindow
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
    readonly property color iconColor: online
        ? Theme.foregroundSurfaceVariant
        : limited ? Theme.warning : Theme.error

    implicitWidth: Theme.itemHeight
    implicitHeight: Theme.itemHeight
    radius: Theme.radiusPill
    color: pointer.containsMouse || details.visible
        ? Theme.surfaceContainerHigh : "transparent"
    scale: pointer.pressed ? 0.92 : 1

    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionFast
            easing.type: Theme.easeEnter
        }
    }

    Canvas {
        id: networkIcon
        anchors.centerIn: parent
        width: 18
        height: 18
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = root.iconColor;
            ctx.fillStyle = root.iconColor;
            ctx.lineWidth = 1.8;
            ctx.lineCap = "round";

            if (root.connectedWifi) {
                const strength = root.signalPercent;
                ctx.beginPath();
                ctx.arc(9, 15, 2, Math.PI * 1.18, Math.PI * 1.82);
                ctx.stroke();
                if (strength > 33) {
                    ctx.beginPath();
                    ctx.arc(9, 15, 5, Math.PI * 1.18, Math.PI * 1.82);
                    ctx.stroke();
                }
                if (strength > 66) {
                    ctx.beginPath();
                    ctx.arc(9, 15, 8, Math.PI * 1.18, Math.PI * 1.82);
                    ctx.stroke();
                }
                ctx.beginPath();
                ctx.arc(9, 14.5, 1.3, 0, Math.PI * 2);
                ctx.fill();
            } else if (root.online || root.limited) {
                ctx.beginPath();
                ctx.arc(9, 9, 6.5, 0, Math.PI * 2);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(2.8, 9);
                ctx.lineTo(15.2, 9);
                ctx.moveTo(9, 2.5);
                ctx.bezierCurveTo(5.8, 5.5, 5.8, 12.5, 9, 15.5);
                ctx.moveTo(9, 2.5);
                ctx.bezierCurveTo(12.2, 5.5, 12.2, 12.5, 9, 15.5);
                ctx.stroke();
            } else {
                ctx.beginPath();
                ctx.moveTo(4, 4);
                ctx.lineTo(14, 14);
                ctx.moveTo(14, 4);
                ctx.lineTo(4, 14);
                ctx.stroke();
            }
        }

        Connections {
            target: root
            function onIconColorChanged() { networkIcon.requestPaint(); }
            function onConnectedWifiChanged() { networkIcon.requestPaint(); }
            function onSignalPercentChanged() { networkIcon.requestPaint(); }
            function onOnlineChanged() { networkIcon.requestPaint(); }
            function onLimitedChanged() { networkIcon.requestPaint(); }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: details.visible = !details.visible
    }

    PopupWindow {
        id: details
        anchor.window: root.hostWindow
        anchor.rect.x: root.mapToItem(null, 0, 0).x - width + root.width
        anchor.rect.y: root.hostWindow.height
        implicitWidth: 250
        implicitHeight: detailSurface.implicitHeight + Theme.space8
        color: "transparent"
        grabFocus: false
        visible: false

        Surface {
            id: detailSurface
            y: Theme.space8
            width: parent.width
            implicitHeight: detailColumn.implicitHeight + Theme.space24
            radius: Theme.radiusLarge
            color: Theme.surface

            Column {
                id: detailColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Theme.space12
                }
                spacing: Theme.space8

                StyledText {
                    width: parent.width
                    text: root.connectedWifi?.name
                        || (root.online ? "Network" : "No connection")
                    font.pixelSize: Theme.fontTitle
                    font.weight: Theme.fontWeightLabel
                    elide: Text.ElideRight
                }
                StyledText {
                    width: parent.width
                    text: root.connectedWifi
                        ? "Wi-Fi  •  " + root.signalPercent + "% signal"
                        : root.online ? "Connected  •  non-Wi-Fi"
                        : root.limited ? "Limited internet access"
                        : "Offline"
                    color: root.iconColor
                    font.pixelSize: Theme.fontSmall
                }
                StyledText {
                    width: parent.width
                    text: "Connection controls will live in Quick Settings"
                    color: Theme.outline
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
