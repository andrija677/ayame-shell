import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland
import "../../components"
import "../../settings"
import "../../services"
import "../../theme"
import "../settings"

PanelWindow {
    id: root

    signal powerRequested()
    signal utilityRequested(string page)

    required property var hostWindow
    readonly property bool open: panelOpen || settingsPanel.panelOpen
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink?.audio ?? null
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryAvailable: battery?.isPresent
        && battery?.isLaptopBattery
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property var connectedWifi: {
        for (const device of Networking.devices.values) {
            if (device.type !== DeviceType.Wifi)
                continue;
            for (const network of device.networks.values) {
                if (network.connected)
                    return network;
            }
        }
        return null;
    }
    readonly property var connectedDevice: {
        for (const device of Networking.devices.values) {
            if (device.connected)
                return device;
        }
        return null;
    }
    readonly property bool networkOnline: Networking.connectivity
        === NetworkConnectivity.Full
    readonly property bool networkLimited: Networking.connectivity
        === NetworkConnectivity.Limited
        || Networking.connectivity === NetworkConnectivity.Portal
    readonly property int connectedBluetoothCount: {
        let count = 0;
        for (let device of Bluetooth.devices.values) {
            if (device.connected)
                count++;
        }
        return count;
    }
    readonly property var powerProfileOptions: {
        const options = [
            { label: "Saver", value: PowerProfile.PowerSaver },
            { label: "Balanced", value: PowerProfile.Balanced }
        ];
        if (PowerProfiles.hasPerformanceProfile)
            options.push({ label: "Performance", value: PowerProfile.Performance });
        return options;
    }
    property bool panelOpen: false
    property bool keepAwake: false

    MotionProgress { id: motion; open: root.panelOpen }

    function toggle() {
        if (open)
            closePanel();
        else
            openPanel();
    }

    function openPanel() {
        if (settingsPanel.panelOpen)
            settingsPanel.closePanel();
        closeTimer.stop();
        panelOpen = false;
        visible = true;
        openTimer.restart();
    }

    function closePanel() {
        openTimer.stop();
        panelOpen = false;
        if (settingsPanel.panelOpen) {
            closeTimer.stop();
            settingsPanel.closePanel();
        } else {
            closeTimer.restart();
        }
    }

    function openSettings() {
        openTimer.stop();
        closeTimer.stop();
        panelOpen = false;
        visible = true;
        settingsPanel.openPanel();
    }

    function setVolumeFromX(position) {
        if (!audio)
            return;
        audio.volume = Math.max(0, Math.min(1, position / volumeTrack.width));
    }

    screen: hostWindow.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "ayame-shell-quick-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible
        ? WlrLayershell.OnDemand : WlrLayershell.None

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.closePanel()
    }

    onVisibleChanged: {
        if (!visible) {
            closeTimer.stop();
            panelOpen = false;
        }
    }

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    IdleInhibitor {
        window: root.hostWindow
        enabled: root.keepAwake
    }

    Timer {
        id: openTimer
        interval: Theme.motionMapGrace
        onTriggered: root.panelOpen = true
    }

    Timer {
        id: closeTimer
        interval: Theme.motionNormal + Theme.motionUnmapGrace
        onTriggered: root.visible = false
    }

    MouseArea { anchors.fill: parent; onClicked: root.closePanel() }

    Surface {
        id: panel
        anchors {
            top: parent.top
            right: parent.right
            topMargin: -Theme.space4
                + (Theme.space8 + Theme.space4) * motion.value
            rightMargin: Theme.outerMargin
        }
        width: 340
        implicitHeight: content.implicitHeight + Theme.space24
        opacity: motion.value
        radius: Theme.radiusLarge
        color: Theme.surface

        MouseArea { anchors.fill: parent }

        transform: Scale {
            id: panelScale
            origin.x: panel.width
            origin.y: 0
            xScale: 0.92 + 0.08 * motion.value
            yScale: 0.84 + 0.16 * motion.value
        }

        ColumnLayout {
            id: content
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Theme.space12
            }
            spacing: Theme.space12

            StyledText {
                text: "Quick Settings"
                font.pixelSize: Theme.fontTitle
                font.weight: Theme.fontWeightTitle
            }

            Surface {
                Layout.fillWidth: true
                implicitHeight: 82
                color: Theme.surfaceContainer

                ColumnLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    spacing: Theme.space8

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: "Volume"; Layout.fillWidth: true }
                        StyledText {
                            text: root.audio?.muted ? "MUTED"
                                : Math.round((root.audio?.volume ?? 0) * 100) + "%"
                            color: root.audio?.muted
                                ? Theme.error : Theme.foregroundSurfaceVariant
                            font.pixelSize: Theme.fontSmall
                            font.weight: Theme.fontWeightLabel
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space8

                        Rectangle {
                            implicitWidth: 42
                            implicitHeight: 24
                            radius: Theme.radiusPill
                            color: mutePointer.containsMouse
                                ? Theme.surfaceContainerHigh : "transparent"
                            StyledText {
                                anchors.centerIn: parent
                                text: root.audio?.muted ? "ON" : "MUTE"
                                font.pixelSize: 9
                                font.weight: Theme.fontWeightTitle
                            }
                            MouseArea {
                                id: mutePointer
                                anchors.fill: parent
                                enabled: root.audio !== null
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.audio.muted = !root.audio.muted
                            }
                        }

                        Rectangle {
                            id: volumeTrack
                            Layout.fillWidth: true
                            implicitHeight: 6
                            radius: 3
                            color: Theme.outlineVariant

                            Rectangle {
                                width: parent.width * Math.min(1, root.audio?.volume ?? 0)
                                height: parent.height
                                radius: parent.radius
                                color: root.audio?.muted ? Theme.outline : Theme.primary
                            }
                            Rectangle {
                                x: Math.max(0, Math.min(parent.width - width,
                                    parent.width * Math.min(1, root.audio?.volume ?? 0)
                                    - width / 2))
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 14
                                radius: 7
                                color: root.audio?.muted ? Theme.outline : Theme.primary
                            }
                            MouseArea {
                                anchors { fill: parent; margins: -Theme.space8 }
                                enabled: root.audio !== null
                                cursorShape: Qt.PointingHandCursor
                                onPressed: event => root.setVolumeFromX(event.x)
                                onPositionChanged: event => {
                                    if (pressed)
                                        root.setVolumeFromX(event.x);
                                }
                            }
                        }
                    }
                }
            }

            QuickToggleTile {
                Layout.fillWidth: true
                title: root.connectedWifi?.name || "Network"
                subtitle: SessionService.networkingBusy ? "Switching…"
                    : !SessionService.networkingEnabled ? "All connections disabled"
                    : root.connectedWifi
                        ? "Wi-Fi • " + Math.round(root.connectedWifi.signalStrength) + "% signal"
                        : root.networkOnline ? "Connected • wired or virtual"
                        : root.networkLimited ? "Limited internet access"
                        : Networking.wifiHardwareEnabled && Networking.wifiEnabled
                            ? "Wi-Fi enabled • not connected" : "Offline"
                checked: Networking.wifiHardwareEnabled
                    ? Networking.wifiEnabled : SessionService.networkingEnabled
                interactive: !SessionService.networkingBusy
                onActivated: {
                    if (Networking.wifiHardwareEnabled)
                        Networking.wifiEnabled = !checked;
                    else
                        SessionService.toggleNetworking();
                }
            }

            QuickToggleTile {
                Layout.fillWidth: true
                visible: root.bluetoothAdapter !== null
                title: "Bluetooth"
                subtitle: !root.bluetoothAdapter?.enabled ? "Off"
                    : root.connectedBluetoothCount === 0 ? "No devices connected"
                    : root.connectedBluetoothCount === 1 ? "1 device connected"
                    : root.connectedBluetoothCount + " devices connected"
                checked: root.bluetoothAdapter?.enabled ?? false
                interactive: root.bluetoothAdapter !== null
                onActivated: root.bluetoothAdapter.enabled
                    = !root.bluetoothAdapter.enabled
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8

                QuickToggleTile {
                    Layout.fillWidth: true
                    title: "Keep awake"
                    subtitle: checked ? "Screen stays on" : "Normal idle rules"
                    checked: root.keepAwake
                    onActivated: root.keepAwake = !checked
                }

                QuickToggleTile {
                    Layout.fillWidth: true
                    title: "Gaming mode"
                    subtitle: SessionService.gameModeBusy ? "Switching…"
                        : checked ? "Effects reduced" : "Normal desktop"
                    checked: SessionService.gameMode
                    interactive: !SessionService.gameModeBusy
                    onActivated: SessionService.toggleGameMode()
                }
            }

            Surface {
                Layout.fillWidth: true
                implicitHeight: 78
                color: Theme.surfaceContainer

                ColumnLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    spacing: Theme.space8

                    StyledText {
                        text: "Power profile"
                        font.weight: Theme.fontWeightLabel
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space4

                        Repeater {
                            model: root.powerProfileOptions

                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 26
                                radius: Theme.radiusPill
                                color: PowerProfiles.profile === modelData.value
                                    ? Theme.primary : profilePointer.containsMouse
                                        ? Theme.surfaceContainerHigh
                                        : Theme.outlineVariant

                                StyledText {
                                    anchors.centerIn: parent
                                    text: parent.modelData.label
                                    color: PowerProfiles.profile === parent.modelData.value
                                        ? Theme.foregroundPrimary
                                        : Theme.foregroundSurfaceVariant
                                    font.pixelSize: 9
                                    font.weight: Theme.fontWeightTitle
                                }

                                MouseArea {
                                    id: profilePointer
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: PowerProfiles.profile
                                        = parent.modelData.value
                                }
                            }
                        }
                    }
                }
            }

            Surface {
                Layout.fillWidth: true
                implicitHeight: root.batteryAvailable ? 62 : 0
                visible: root.batteryAvailable
                color: Theme.surfaceContainer
                RowLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    StyledText { text: "Battery"; Layout.fillWidth: true }
                    StyledText {
                        text: Math.round(root.battery?.percentage ?? 0) + "%"
                        color: Theme.foregroundSurfaceVariant
                        font.pixelSize: Theme.fontSmall
                        font.weight: Theme.fontWeightLabel
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                uniformCellWidths: true
                uniformCellHeights: true
                rowSpacing: Theme.space8
                columnSpacing: Theme.space8

                QuickActionButton {
                    Layout.fillWidth: true
                    icon: "󰌌"
                    label: "Keybinds"
                    onActivated: {
                        root.closePanel();
                        root.utilityRequested("keys");
                    }
                }

                QuickActionButton {
                    Layout.fillWidth: true
                    icon: "󰄀"
                    label: "Screenshot"
                    onActivated: {
                        root.closePanel();
                        root.utilityRequested("capture");
                    }
                }

                QuickActionButton {
                    Layout.fillWidth: true
                    icon: "󰒓"
                    label: "Ayame Settings"
                    primary: true
                    onActivated: root.openSettings()
                }

                QuickActionButton {
                    Layout.fillWidth: true
                    icon: "󰐥"
                    label: "Power"
                    danger: true
                    onActivated: {
                        root.closePanel();
                        root.powerRequested();
                    }
                }
            }
        }
    }

    SettingsPopup {
        id: settingsPanel
        hostWindow: root.hostWindow
        onDismissed: {
            closeTimer.stop();
            root.visible = false;
        }
    }
}
