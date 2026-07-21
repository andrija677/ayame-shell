import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Wayland
import "../../components"
import "../../theme"

PanelWindow {
    id: root

    required property var hostWindow
    required property var wifiDevice
    property bool panelOpen: false
    property var selectedNetwork: null
    property string errorText: ""

    readonly property var networks: {
        const items = (wifiDevice?.networks?.values ?? [])
            .filter(network => (network.name || "").trim().length > 0);
        items.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.known !== b.known) return a.known ? -1 : 1;
            return b.signalStrength - a.signalStrength;
        });
        return items;
    }

    function openPanel() {
        closeTimer.stop();
        selectedNetwork = null;
        errorText = "";
        visible = true;
        panelOpen = true;
        if (wifiDevice)
            wifiDevice.scannerEnabled = true;
    }

    function closePanel() {
        panelOpen = false;
        selectedNetwork = null;
        if (wifiDevice)
            wifiDevice.scannerEnabled = false;
        closeTimer.restart();
    }

    function chooseNetwork(network) {
        errorText = "";
        if (network.connected) {
            network.disconnect();
        } else if (network.known || network.security === WifiSecurityType.Open) {
            network.connect();
        } else {
            selectedNetwork = network;
            passwordInput.text = "";
            Qt.callLater(() => passwordInput.forceActiveFocus());
        }
    }

    function connectSelected() {
        if (!selectedNetwork || passwordInput.text.length === 0)
            return;
        selectedNetwork.connectWithPsk(passwordInput.text);
        passwordInput.text = "";
        selectedNetwork = null;
    }

    function refreshScan() {
        if (!wifiDevice || !Networking.wifiEnabled)
            return;
        wifiDevice.scannerEnabled = false;
        scanRestart.start();
    }

    screen: hostWindow.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    visible: false
    WlrLayershell.namespace: "ayame-shell-wifi"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible
        ? WlrLayershell.OnDemand : WlrLayershell.None

    Shortcut { sequence: "Escape"; onActivated: root.closePanel() }
    Timer {
        id: closeTimer
        interval: Theme.motionNormal + Theme.motionUnmapGrace
        onTriggered: root.visible = false
    }
    Timer {
        id: scanRestart
        interval: 120
        onTriggered: {
            if (root.wifiDevice && root.visible)
                root.wifiDevice.scannerEnabled = true;
        }
    }

    MouseArea { anchors.fill: parent; onClicked: root.closePanel() }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        opacity: root.panelOpen ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }
    }

    Surface {
        id: panel
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
                    text: "Wi-Fi Networks"
                    font.pixelSize: Theme.fontTitle
                    font.weight: Theme.fontWeightTitle
                    Layout.fillWidth: true
                }
                StyledText {
                    text: "Refresh"
                    color: refreshPointer.containsMouse ? Theme.primary : Theme.outline
                    font.pixelSize: 9
                    font.weight: Theme.fontWeightTitle
                    MouseArea {
                        id: refreshPointer
                        anchors { fill: parent; margins: -Theme.space8 }
                        enabled: Networking.wifiEnabled
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.refreshScan()
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
                title: "Wi-Fi"
                subtitle: checked ? "Scanning for nearby networks" : "Wireless disabled"
                checked: Networking.wifiEnabled
                onActivated: Networking.wifiEnabled = !checked
            }

            StyledText {
                Layout.fillWidth: true
                visible: Networking.wifiEnabled && root.networks.length === 0
                text: "Looking for networks…"
                color: Theme.foregroundSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSmall
            }

            ListView {
                Layout.fillWidth: true
                implicitHeight: Networking.wifiEnabled
                    ? Math.min(contentHeight, 360) : 0
                visible: Networking.wifiEnabled
                clip: true
                spacing: Theme.space4
                model: root.networks

                delegate: Surface {
                    required property var modelData
                    width: ListView.view.width
                    implicitHeight: 58
                    color: modelData.connected
                        ? Theme.primaryContainer : Theme.surfaceContainer

                    Connections {
                        target: modelData
                        function onConnectionFailed(reason) {
                            root.errorText = "Could not connect to " + modelData.name;
                        }
                    }

                    RowLayout {
                        z: 1
                        anchors { fill: parent; margins: Theme.space8 }
                        spacing: Theme.space8
                        StyledText {
                            text: modelData.signalStrength >= 67 ? "󰤨"
                                : modelData.signalStrength >= 34 ? "󰤥" : "󰤟"
                            color: modelData.connected ? Theme.primary
                                : Theme.foregroundSurfaceVariant
                            font.pixelSize: 17
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.weight: Theme.fontWeightLabel
                                elide: Text.ElideRight
                            }
                            StyledText {
                                text: modelData.connected ? "Connected"
                                    : modelData.stateChanging ? "Connecting…"
                                    : modelData.known ? "Saved • " + Math.round(modelData.signalStrength) + "%"
                                    : WifiSecurityType.toString(modelData.security)
                                        + " • " + Math.round(modelData.signalStrength) + "%"
                                color: Theme.foregroundSurfaceVariant
                                font.pixelSize: Theme.fontSmall
                            }
                        }
                        StyledText {
                            visible: modelData.known && !modelData.connected
                            text: "Forget"
                            color: forgetPointer.containsMouse ? Theme.error : Theme.outline
                            font.pixelSize: 9
                            font.weight: Theme.fontWeightTitle
                            MouseArea {
                                id: forgetPointer
                                anchors { fill: parent; margins: -Theme.space4 }
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    modelData.forget();
                                    root.errorText = "";
                                }
                            }
                        }
                        StyledText {
                            text: modelData.connected ? "Disconnect" : "Connect"
                            color: networkPointer.containsMouse ? Theme.primary : Theme.outline
                            font.pixelSize: 9
                            font.weight: Theme.fontWeightTitle
                        }
                    }

                    MouseArea {
                        id: networkPointer
                        z: 0
                        anchors.fill: parent
                        enabled: !modelData.stateChanging
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.chooseNetwork(modelData)
                    }
                }
            }

            Surface {
                Layout.fillWidth: true
                implicitHeight: root.selectedNetwork ? 112 : 0
                visible: root.selectedNetwork !== null
                color: Theme.surfaceContainerHigh
                clip: true

                ColumnLayout {
                    anchors { fill: parent; margins: Theme.space8 }
                    spacing: Theme.space6
                    StyledText {
                        text: "Password for " + (root.selectedNetwork?.name ?? "network")
                        font.weight: Theme.fontWeightLabel
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: Theme.radiusMedium
                        color: Theme.surfaceContainer
                        border.color: passwordInput.activeFocus
                            ? Theme.primary : Theme.outlineVariant
                        TextInput {
                            id: passwordInput
                            anchors { fill: parent; leftMargin: Theme.space8; rightMargin: Theme.space8 }
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: Theme.foregroundSurface
                            font.family: Theme.fontFamily
                            onAccepted: root.connectSelected()
                        }
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        StyledText {
                            text: "Cancel"
                            color: cancelPointer.containsMouse ? Theme.primary : Theme.outline
                            MouseArea {
                                id: cancelPointer
                                anchors { fill: parent; margins: -Theme.space6 }
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedNetwork = null
                            }
                        }
                        Rectangle {
                            implicitWidth: 78; implicitHeight: 28
                            radius: Theme.radiusPill
                            color: connectPointer.containsMouse
                                ? Theme.primary : Theme.primaryContainer
                            StyledText {
                                anchors.centerIn: parent
                                text: "CONNECT"
                                font.pixelSize: 9
                                font.weight: Theme.fontWeightTitle
                            }
                            MouseArea {
                                id: connectPointer
                                anchors.fill: parent
                                enabled: passwordInput.text.length > 0
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.connectSelected()
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.errorText.length > 0
                text: root.errorText
                color: Theme.error
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
            }
        }
    }
}
