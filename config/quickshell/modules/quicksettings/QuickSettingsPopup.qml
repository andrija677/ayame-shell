import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
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

PopupWindow {
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
        closeTimer.restart();
        if (settingsPanel.panelOpen)
            settingsPanel.closePanel();
    }

    function setVolumeFromX(position) {
        if (!audio)
            return;
        audio.volume = Math.max(0, Math.min(1, position / volumeTrack.width));
    }

    anchor.window: hostWindow
    anchor.rect.x: hostWindow.width - width - Theme.outerMargin
    anchor.rect.y: hostWindow.height
    implicitWidth: 340
    implicitHeight: panel.implicitHeight + Theme.space8
    color: "transparent"
    grabFocus: true

    HyprlandFocusGrab {
        windows: [root, settingsPanel, root.hostWindow]
        active: root.visible || settingsPanel.visible
    }

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

    Surface {
        id: panel
        width: parent.width
        implicitHeight: content.implicitHeight + Theme.space24
        y: -Theme.space4 + (Theme.space8 + Theme.space4) * motion.value
        opacity: motion.value
        radius: Theme.radiusLarge
        color: Theme.surface

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
                font.weight: Theme.fontWeightLabel
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
                title: "Networking"
                subtitle: SessionService.networkingBusy ? "Switching…"
                    : checked ? "Connections enabled" : "All connections disabled"
                checked: SessionService.networkingEnabled
                interactive: !SessionService.networkingBusy
                onActivated: SessionService.toggleNetworking()
            }

            QuickToggleTile {
                Layout.fillWidth: true
                visible: Networking.wifiHardwareEnabled
                title: "Wi-Fi"
                subtitle: checked ? "Wireless enabled" : "Wireless disabled"
                checked: Networking.wifiEnabled
                onActivated: Networking.wifiEnabled = !checked
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
                        : checked ? "Performance session" : "Normal desktop"
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
                implicitHeight: 62
                color: Theme.surfaceContainer
                RowLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    StyledText { text: "Network"; Layout.fillWidth: true }
                    StyledText {
                        text: Networking.connectivity === NetworkConnectivity.Full
                            ? "CONNECTED"
                            : Networking.connectivity === NetworkConnectivity.Limited
                                || Networking.connectivity === NetworkConnectivity.Portal
                                ? "LIMITED" : "OFFLINE"
                        color: Networking.connectivity === NetworkConnectivity.Full
                            ? Theme.success
                            : Networking.connectivity === NetworkConnectivity.None
                                ? Theme.error : Theme.warning
                        font.pixelSize: Theme.fontSmall
                        font.weight: Theme.fontWeightLabel
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

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Theme.radiusPill
                    color: keysPointer.containsMouse ? Theme.primary : Theme.surfaceContainerHigh
                    StyledText { anchors.centerIn: parent; text: "Keybinds"; font.pixelSize: 10; font.weight: Theme.fontWeightTitle }
                    MouseArea {
                        id: keysPointer
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.closePanel(); root.utilityRequested("keys"); }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Theme.radiusPill
                    color: captureUtilityPointer.containsMouse ? Theme.primary : Theme.surfaceContainerHigh
                    StyledText { anchors.centerIn: parent; text: "Screenshot"; font.pixelSize: 10; font.weight: Theme.fontWeightTitle }
                    MouseArea {
                        id: captureUtilityPointer
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.closePanel(); root.utilityRequested("capture"); }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.radiusPill
                    color: settingsPointer.containsMouse
                        ? Theme.primary : Theme.primaryContainer
                    StyledText {
                        anchors.centerIn: parent
                        text: "Ayame Settings"
                        color: settingsPointer.containsMouse
                            ? Theme.foregroundPrimary : Theme.foregroundPrimaryContainer
                        font.pixelSize: 10
                        font.weight: Theme.fontWeightTitle
                    }
                    MouseArea {
                        id: settingsPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.closePanel();
                            settingsPanel.openPanel();
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 88
                    implicitHeight: 38
                    radius: Theme.radiusPill
                    color: powerPointer.containsMouse ? Theme.error : Theme.surfaceContainerHigh
                    StyledText {
                        anchors.centerIn: parent
                        text: "Power"
                        color: powerPointer.containsMouse
                            ? Theme.foregroundPrimary : Theme.foregroundSurface
                        font.pixelSize: 10
                        font.weight: Theme.fontWeightTitle
                    }
                    MouseArea {
                        id: powerPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.closePanel();
                            root.powerRequested();
                        }
                    }
                }
            }
        }
    }

    SettingsPopup {
        id: settingsPanel
        hostWindow: root.hostWindow
    }
}
