import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "../../components"
import "../../settings"
import "../../services"
import "../../theme"

PopupWindow {
    id: root

    required property var hostWindow
    readonly property bool open: panelOpen
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
            { label: "SAVER", value: PowerProfile.PowerSaver },
            { label: "BALANCED", value: PowerProfile.Balanced }
        ];
        if (PowerProfiles.hasPerformanceProfile)
            options.push({ label: "PERFORMANCE", value: PowerProfile.Performance });
        return options;
    }
    property bool panelOpen: false

    function toggle() {
        if (panelOpen)
            closePanel();
        else
            openPanel();
    }

    function openPanel() {
        closeTimer.stop();
        visible = true;
        panelOpen = true;
    }

    function closePanel() {
        panelOpen = false;
        closeTimer.restart();
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
    grabFocus: false

    onVisibleChanged: {
        if (!visible) {
            closeTimer.stop();
            panelOpen = false;
        }
    }

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    Timer {
        id: closeTimer
        interval: Theme.motionNormal
        onTriggered: root.visible = false
    }

    Surface {
        id: panel
        width: parent.width
        implicitHeight: content.implicitHeight + Theme.space24
        y: root.panelOpen ? Theme.space8 : -Theme.space4
        opacity: root.panelOpen ? 1 : 0
        radius: Theme.radiusLarge
        color: Theme.surface

        transform: Scale {
            id: panelScale
            origin.x: panel.width
            origin.y: 0
            xScale: root.panelOpen ? 1 : 0.92
            yScale: root.panelOpen ? 1 : 0.84

            Behavior on xScale {
                NumberAnimation {
                    duration: root.panelOpen ? Theme.motionSlow : Theme.motionNormal
                    easing.type: root.panelOpen ? Easing.OutCubic : Easing.InCubic
                }
            }
            Behavior on yScale {
                NumberAnimation {
                    duration: root.panelOpen ? Theme.motionSlow : Theme.motionNormal
                    easing.type: root.panelOpen ? Easing.OutCubic : Easing.InCubic
                }
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: root.panelOpen ? Theme.motionSlow : Theme.motionNormal
                easing.type: root.panelOpen ? Easing.OutCubic : Easing.InCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.motionNormal
                easing.type: root.panelOpen ? Easing.OutCubic : Easing.InCubic
            }
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

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8

                QuickToggleTile {
                    Layout.fillWidth: true
                    title: "Window title"
                    subtitle: checked ? "Visible in bar" : "Hidden from bar"
                    checked: ShellConfig.activeWindowEnabled
                    onActivated: ShellConfig.activeWindowEnabled = !checked
                }

                QuickToggleTile {
                    Layout.fillWidth: true
                    title: "Passive tray"
                    subtitle: checked ? "Icons included" : "Active icons only"
                    checked: ShellConfig.showPassiveTrayItems
                    onActivated: ShellConfig.showPassiveTrayItems = !checked
                }
            }

            QuickToggleTile {
                Layout.fillWidth: true
                title: "Dock"
                subtitle: checked ? "Visible on desktop" : "Hidden"
                checked: ShellConfig.dockEnabled
                onActivated: ShellConfig.dockEnabled = !checked
            }

            QuickToggleTile {
                Layout.fillWidth: true
                title: "Animations"
                subtitle: checked ? "Expressive motion" : "Reduced motion"
                checked: ShellConfig.animationsEnabled
                onActivated: ShellConfig.animationsEnabled = !checked
            }

            Surface {
                Layout.fillWidth: true
                implicitHeight: 72
                color: Theme.surfaceContainer

                RowLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    spacing: Theme.space8
                    ColumnLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: "Weather"
                            font.weight: Theme.fontWeightLabel
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: WeatherService.configured
                                ? ShellConfig.weatherLocationName : "No city configured"
                            color: Theme.foregroundSurfaceVariant
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                        }
                    }
                    Rectangle {
                        implicitWidth: 30
                        implicitHeight: 28
                        radius: Theme.radiusPill
                        color: refreshPointer.containsMouse
                            ? Theme.surfaceContainerHigh : "transparent"
                        visible: WeatherService.configured
                        StyledText {
                            anchors.centerIn: parent
                            text: "↻"
                            font.pixelSize: 16
                        }
                        MouseArea {
                            id: refreshPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WeatherService.refresh()
                        }
                    }
                    Rectangle {
                        implicitWidth: 46
                        implicitHeight: 28
                        radius: Theme.radiusPill
                        color: unitPointer.containsMouse
                            ? Theme.surfaceContainerHigh : Theme.outlineVariant
                        StyledText {
                            anchors.centerIn: parent
                            text: ShellConfig.weatherTemperatureUnit === "celsius"
                                ? "°C" : "°F"
                            font.family: Theme.fontFamilyNumeric
                        }
                        MouseArea {
                            id: unitPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ShellConfig.weatherTemperatureUnit
                                    = ShellConfig.weatherTemperatureUnit === "celsius"
                                        ? "fahrenheit" : "celsius";
                                WeatherService.refresh();
                            }
                        }
                    }
                    Rectangle {
                        implicitWidth: 66
                        implicitHeight: 28
                        radius: Theme.radiusPill
                        color: weatherPointer.containsMouse
                            ? Theme.primary : Theme.primaryContainer
                        StyledText {
                            anchors.centerIn: parent
                            text: WeatherService.configured ? "CHANGE" : "SET UP"
                            font.pixelSize: 9
                            font.weight: Theme.fontWeightTitle
                        }
                        MouseArea {
                            id: weatherPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: weatherSetup.open()
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
        }
    }

    WeatherSetupPopup {
        id: weatherSetup
        hostWindow: root.hostWindow
    }
}
