import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland
import "../../components"
import "../../theme"

PanelWindow {
    id: root

    required property var hostWindow
    required property var adapter
    property bool panelOpen: false

    readonly property var devices: {
        const items = (adapter?.devices?.values ?? []).slice();
        items.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            return (a.name || a.deviceName).localeCompare(b.name || b.deviceName);
        });
        return items;
    }

    function openPanel() {
        closeTimer.stop();
        visible = true;
        panelOpen = true;
        if (adapter?.enabled)
            adapter.discovering = true;
    }

    function closePanel() {
        panelOpen = false;
        if (adapter)
            adapter.discovering = false;
        closeTimer.restart();
    }

    function toggleDevice(device) {
        if (device.connected)
            device.disconnect();
        else if (device.paired)
            device.connect();
        else
            device.pair();
    }

    screen: hostWindow.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    visible: false
    WlrLayershell.namespace: "ayame-shell-bluetooth"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible
        ? WlrLayershell.OnDemand : WlrLayershell.None

    Shortcut { sequence: "Escape"; onActivated: root.closePanel() }
    Timer {
        id: closeTimer
        interval: Theme.motionNormal + Theme.motionUnmapGrace
        onTriggered: root.visible = false
    }

    MouseArea { anchors.fill: parent; onClicked: root.closePanel() }
    Rectangle {
        anchors.fill: parent
        color: Theme.background
        opacity: root.panelOpen ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }
    }

    Surface {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: Theme.space8
            rightMargin: Theme.outerMargin
        }
        width: 380
        implicitHeight: content.implicitHeight + Theme.space24
        radius: Theme.radiusLarge
        color: Theme.surface
        opacity: root.panelOpen ? 1 : 0
        scale: root.panelOpen ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }
        Behavior on scale {
            NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter }
        }
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: content
            anchors { fill: parent; margins: Theme.space12 }
            spacing: Theme.space8

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: "Bluetooth Devices"
                    font.pixelSize: Theme.fontTitle
                    font.weight: Theme.fontWeightTitle
                    Layout.fillWidth: true
                }
                StyledText {
                    text: root.adapter?.discovering ? "Scanning…" : "Scan"
                    color: scanPointer.containsMouse ? Theme.primary : Theme.outline
                    font.pixelSize: 9
                    font.weight: Theme.fontWeightTitle
                    MouseArea {
                        id: scanPointer
                        anchors { fill: parent; margins: -Theme.space8 }
                        enabled: root.adapter?.enabled ?? false
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.adapter.discovering = !root.adapter.discovering
                    }
                }
                StyledText {
                    text: "Close"
                    color: closePointer.containsMouse ? Theme.primary : Theme.outline
                    font.pixelSize: 9
                    font.weight: Theme.fontWeightTitle
                    MouseArea {
                        id: closePointer
                        anchors { fill: parent; margins: -Theme.space8 }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closePanel()
                    }
                }
            }

            QuickToggleTile {
                Layout.fillWidth: true
                title: "Bluetooth"
                subtitle: checked ? "Ready to connect" : "Wireless devices disabled"
                checked: root.adapter?.enabled ?? false
                interactive: root.adapter !== null
                onActivated: {
                    root.adapter.enabled = !checked;
                    if (!checked)
                        root.adapter.discovering = true;
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: (root.adapter?.enabled ?? false) && root.devices.length === 0
                text: root.adapter?.discovering
                    ? "Looking for nearby devices…" : "No Bluetooth devices found"
                color: Theme.foregroundSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSmall
            }

            ListView {
                Layout.fillWidth: true
                implicitHeight: root.adapter?.enabled
                    ? Math.min(contentHeight, 420) : 0
                visible: root.adapter?.enabled ?? false
                clip: true
                spacing: Theme.space4
                model: root.devices

                delegate: Surface {
                    required property var modelData
                    width: ListView.view.width
                    implicitHeight: 58
                    color: modelData.connected
                        ? Theme.primaryContainer : Theme.surfaceContainer

                    RowLayout {
                        z: 1
                        anchors { fill: parent; margins: Theme.space8 }
                        spacing: Theme.space8
                        StyledText {
                            text: "󰂯"
                            color: modelData.connected ? Theme.primary
                                : Theme.foregroundSurfaceVariant
                            font.pixelSize: 18
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.name || modelData.deviceName || modelData.address
                                font.weight: Theme.fontWeightLabel
                                elide: Text.ElideRight
                            }
                            StyledText {
                                text: modelData.connected
                                    ? (modelData.batteryAvailable
                                        ? "Connected • " + Math.round(modelData.battery * 100) + "% battery"
                                        : "Connected")
                                    : modelData.pairing ? "Pairing…"
                                    : modelData.state === BluetoothDeviceState.Connecting
                                        ? "Connecting…" : modelData.paired ? "Paired" : "Nearby"
                                color: Theme.foregroundSurfaceVariant
                                font.pixelSize: Theme.fontSmall
                            }
                        }
                        StyledText {
                            visible: modelData.paired && !modelData.connected
                            text: "Forget"
                            color: forgetPointer.containsMouse ? Theme.error : Theme.outline
                            font.pixelSize: 9
                            font.weight: Theme.fontWeightTitle
                            MouseArea {
                                id: forgetPointer
                                anchors { fill: parent; margins: -Theme.space4 }
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.forget()
                            }
                        }
                        StyledText {
                            text: modelData.connected ? "Disconnect"
                                : modelData.paired ? "Connect" : "Pair"
                            color: devicePointer.containsMouse ? Theme.primary : Theme.outline
                            font.pixelSize: 9
                            font.weight: Theme.fontWeightTitle
                        }
                    }

                    MouseArea {
                        id: devicePointer
                        anchors.fill: parent
                        enabled: !modelData.pairing
                            && modelData.state !== BluetoothDeviceState.Connecting
                            && modelData.state !== BluetoothDeviceState.Disconnecting
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.toggleDevice(modelData)
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: "Some devices may ask you to confirm a pairing code in another system dialog."
                color: Theme.foregroundSurfaceVariant
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: root.adapter?.enabled ?? false
            }
        }
    }
}
