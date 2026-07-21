import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"

PanelWindow {
    id: root

    signal dismissed()

    required property var hostWindow
    property bool panelOpen: false
    property bool otherQuickshellDetected: false
    property bool updateBusy: false
    property string updateStatus: "Install the newest version from GitHub :3"

    MotionProgress { id: motion; open: root.panelOpen }

    Component.onCompleted: quickshellDetector.running = true

    Process {
        id: quickshellDetector
        command: [
            "sh", "-c",
            "pgrep -x qs | grep -vx " + Quickshell.processId
                + " | grep -q . && echo 1 || echo 0"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.otherQuickshellDetected = text.trim() === "1";
                if (!root.otherQuickshellDetected)
                    ShellConfig.notificationServerEnabled = true;
            }
        }
    }

    Process {
        id: updateProcess
        command: [Quickshell.shellDir + "/../../scripts/ayame-update.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    root.updateStatus = text.trim();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    root.updateStatus = "Update failed • check update.log";
            }
        }
        onRunningChanged: root.updateBusy = running
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.updateStatus = "Update failed • check update.log";
        }
    }

    function openPanel() {
        closeTimer.stop();
        panelOpen = false;
        visible = true;
        openTimer.restart();
    }

    function closePanel() {
        openTimer.stop();
        panelOpen = false;
        closeTimer.restart();
    }

    function updateAyame() {
        if (updateProcess.running)
            return;
        updateStatus = "Downloading and installing…";
        updateProcess.running = true;
    }

    screen: hostWindow.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "ayame-shell-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible
        ? WlrLayershell.OnDemand : WlrLayershell.None
    visible: false

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

    Timer {
        id: openTimer
        interval: Theme.motionMapGrace
        onTriggered: root.panelOpen = true
    }

    Timer {
        id: closeTimer
        interval: Theme.motionNormal + Theme.motionUnmapGrace
        onTriggered: {
            root.visible = false;
            root.dismissed();
        }
    }

    MouseArea { anchors.fill: parent; onClicked: root.closePanel() }

    Surface {
        id: settingsSurface
        anchors {
            top: parent.top
            right: parent.right
            topMargin: -Theme.space4
                + (Theme.space8 + Theme.space4) * motion.value
            rightMargin: Theme.outerMargin
        }
        width: 460
        height: Math.min(settingsContent.implicitHeight + Theme.space24,
            root.height - Theme.space24)
        opacity: motion.value
        radius: Theme.radiusLarge
        color: Theme.surface

        MouseArea { anchors.fill: parent }

        transform: Scale {
            origin.x: settingsSurface.width
            origin.y: 0
            xScale: 0.94 + 0.06 * motion.value
            yScale: 0.88 + 0.12 * motion.value
        }

        Flickable {
            id: settingsFlickable
            anchors { fill: parent; margins: Theme.space12 }
            contentWidth: width
            contentHeight: settingsContent.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height
            clip: true

            ColumnLayout {
                id: settingsContent
                width: settingsFlickable.width
                    - (settingsFlickable.interactive ? Theme.space8 : 0)
                spacing: Theme.space12

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: "Ayame Settings"
                    font.pixelSize: Theme.fontTitle
                    font.weight: Theme.fontWeightTitle
                    Layout.fillWidth: true
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

            StyledText {
                text: "Appearance"
                color: Theme.primary
                font.pixelSize: 10
                font.weight: Theme.fontWeightTitle
            }

                Surface {
                Layout.fillWidth: true
                implicitHeight: 62
                color: Theme.surfaceContainer
                RowLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    StyledText { text: "Color scheme"; Layout.fillWidth: true }
                    Repeater {
                        model: [
                            { label: "Dark", value: "dark" },
                            { label: "Light", value: "light" }
                        ]
                        Rectangle {
                            required property var modelData
                            implicitWidth: 58
                            implicitHeight: 28
                            radius: Theme.radiusPill
                            color: ShellConfig.colorScheme === modelData.value
                                ? Theme.primary : Theme.outlineVariant
                            StyledText {
                                anchors.centerIn: parent
                                text: parent.modelData.label
                                color: ShellConfig.colorScheme === parent.modelData.value
                                    ? Theme.foregroundPrimary : Theme.foregroundSurfaceVariant
                                font.pixelSize: 9
                                font.weight: Theme.fontWeightTitle
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    ShellConfig.colorScheme = parent.modelData.value;
                                    // Apply this explicitly from the user action as well as
                                    // through the singleton listener. This keeps external KDE,
                                    // Qt and GTK apps in sync even after a live shell update.
                                    AppearanceService.applyColorScheme();
                                    DynamicPalette.syncKitty();
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
                    title: "Wallpaper tint"
                    subtitle: checked ? "Color-rich surfaces" : "Neutral surfaces"
                    checked: ShellConfig.wallpaperTintEnabled
                    onActivated: ShellConfig.wallpaperTintEnabled = !checked
                }
                QuickToggleTile {
                    Layout.fillWidth: true
                    title: "Background blur"
                    subtitle: checked ? "Translucent glass" : "Solid surfaces"
                    checked: ShellConfig.blurEnabled
                    onActivated: ShellConfig.blurEnabled = !checked
                }
            }

            Surface {
                Layout.fillWidth: true
                implicitHeight: 66
                color: Theme.surfaceContainer
                RowLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        StyledText { text: "Wallpaper colors"; font.weight: Theme.fontWeightLabel }
                        StyledText {
                            text: DynamicPalette.active
                                ? (ShellConfig.dynamicColorMode === "automatic"
                                    ? "Following wallpaper • " : "Manual • ")
                                    + ShellConfig.dynamicColorStyle
                                : "Ayame Violet"
                            color: Theme.foregroundSurfaceVariant
                            font.pixelSize: Theme.fontSmall
                        }
                    }
                    Rectangle {
                        implicitWidth: 82
                        implicitHeight: 28
                        radius: Theme.radiusPill
                        color: wallpaperPointer.containsMouse ? Theme.primary : Theme.primaryContainer
                        StyledText {
                            anchors.centerIn: parent
                            text: "Wallpaper"
                            color: wallpaperPointer.containsMouse
                                ? Theme.foregroundPrimary : Theme.foregroundPrimaryContainer
                            font.pixelSize: 9
                            font.weight: Theme.fontWeightTitle
                        }
                        MouseArea {
                            id: wallpaperPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wallpaperPicker.open()
                        }
                    }
                    Rectangle {
                        implicitWidth: 62
                        implicitHeight: 28
                        radius: Theme.radiusPill
                        color: palettePointer.containsMouse ? Theme.primary : Theme.outlineVariant
                        StyledText {
                            anchors.centerIn: parent
                            text: "Colors"
                            color: palettePointer.containsMouse
                                ? Theme.foregroundPrimary : Theme.foregroundSurfaceVariant
                            font.pixelSize: 9
                            font.weight: Theme.fontWeightTitle
                        }
                        MouseArea {
                            id: palettePointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: paletteSetup.open()
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8
                QuickToggleTile {
                    Layout.fillWidth: true
                    title: "Animations"
                    subtitle: checked ? "Expressive motion" : "Reduced motion"
                    checked: ShellConfig.animationsEnabled
                    onActivated: ShellConfig.animationsEnabled = !checked
                }
                QuickToggleTile {
                    Layout.fillWidth: true
                    title: "Compact layout"
                    subtitle: checked ? "Tighter spacing" : "Comfortable spacing"
                    checked: ShellConfig.densityMode === "compact"
                    onActivated: ShellConfig.densityMode = checked ? "normal" : "compact"
                }
            }

            StyledText {
                text: "Shell Layout"
                color: Theme.primary
                font.pixelSize: 10
                font.weight: Theme.fontWeightTitle
            }

            Surface {
                Layout.fillWidth: true
                implicitHeight: 54
                color: Theme.surfaceContainer
                RowLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    StyledText { text: "Clock format"; Layout.fillWidth: true }
                    Repeater {
                        model: [
                            { label: "24-hour", value: "24h" },
                            { label: "12-hour AM/PM", value: "12h" }
                        ]
                        Rectangle {
                            required property var modelData
                            implicitWidth: modelData.value === "12h" ? 106 : 70
                            implicitHeight: 28
                            radius: Theme.radiusPill
                            color: ShellConfig.clockFormat === modelData.value
                                ? Theme.primary : Theme.outlineVariant
                            StyledText {
                                anchors.centerIn: parent
                                text: parent.modelData.label
                                color: ShellConfig.clockFormat === parent.modelData.value
                                    ? Theme.foregroundPrimary : Theme.foregroundSurfaceVariant
                                font.pixelSize: 9
                                font.weight: Theme.fontWeightTitle
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ShellConfig.clockFormat = parent.modelData.value
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
                    title: "Dock"
                    subtitle: checked ? "Visible" : "Hidden"
                    checked: ShellConfig.dockEnabled
                    onActivated: ShellConfig.dockEnabled = !checked
                }
                QuickToggleTile {
                    Layout.fillWidth: true
                    title: "Window title"
                    subtitle: checked ? "Visible in bar" : "Hidden from bar"
                    checked: ShellConfig.activeWindowEnabled
                    onActivated: ShellConfig.activeWindowEnabled = !checked
                }
            }

            QuickToggleTile {
                Layout.fillWidth: true
                title: "Intelligent dock hide"
                subtitle: checked ? "Reveal at the bottom edge" : "Dock stays visible"
                checked: ShellConfig.dockAutoHide
                interactive: ShellConfig.dockEnabled
                onActivated: ShellConfig.dockAutoHide = !checked
            }

            QuickToggleTile {
                Layout.fillWidth: true
                title: "Passive tray icons"
                subtitle: checked ? "Included in system tray" : "Active icons only"
                checked: ShellConfig.showPassiveTrayItems
                onActivated: ShellConfig.showPassiveTrayItems = !checked
            }

            StyledText {
                text: "Services"
                color: Theme.primary
                font.pixelSize: 10
                font.weight: Theme.fontWeightTitle
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8

                QuickToggleTile {
                    Layout.fillWidth: true
                    visible: root.otherQuickshellDetected
                    title: "Ayame notifications"
                    subtitle: checked ? "Owns notification popups" : "Safe preview mode"
                    checked: ShellConfig.notificationServerEnabled
                    onActivated: ShellConfig.notificationServerEnabled = !checked
                }

                QuickToggleTile {
                    Layout.fillWidth: true
                    title: "Do Not Disturb"
                    subtitle: checked ? "History only" : "Popups allowed"
                    checked: ShellConfig.doNotDisturb
                    interactive: ShellConfig.notificationServerEnabled
                    onActivated: ShellConfig.doNotDisturb = !checked
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: !ShellConfig.notificationServerEnabled
                text: "Enable only when Ayame replaces your current notification service."
                color: Theme.warning
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }

            Surface {
                Layout.fillWidth: true
                implicitHeight: 66
                color: Theme.surfaceContainer
                RowLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        StyledText { text: "Weather"; font.weight: Theme.fontWeightLabel }
                        StyledText {
                            text: WeatherService.configured
                                ? ShellConfig.weatherLocationName : "No city configured"
                            color: Theme.foregroundSurfaceVariant
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
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
                            text: ShellConfig.weatherTemperatureUnit === "celsius" ? "°C" : "°F"
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
                        color: weatherPointer.containsMouse ? Theme.primary : Theme.primaryContainer
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

            StyledText {
                text: "Updates"
                color: Theme.primary
                font.pixelSize: 10
                font.weight: Theme.fontWeightTitle
            }

            Surface {
                Layout.fillWidth: true
                implicitHeight: 66
                color: Theme.surfaceContainer

                RowLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    spacing: Theme.space12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space2
                        StyledText {
                            text: "Ayame Shell"
                            font.weight: Theme.fontWeightLabel
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: root.updateStatus
                            color: Theme.foregroundSurfaceVariant
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        implicitWidth: 82
                        implicitHeight: 30
                        radius: Theme.radiusPill
                        color: updatePointer.containsMouse && !root.updateBusy
                            ? Theme.primary : Theme.primaryContainer
                        opacity: root.updateBusy ? 0.65 : 1

                        StyledText {
                            anchors.centerIn: parent
                            text: root.updateBusy ? "Updating…" : "Update"
                            color: updatePointer.containsMouse && !root.updateBusy
                                ? Theme.foregroundPrimary
                                : Theme.foregroundPrimaryContainer
                            font.pixelSize: 9
                            font.weight: Theme.fontWeightTitle
                        }

                        MouseArea {
                            id: updatePointer
                            anchors.fill: parent
                            enabled: !root.updateBusy
                            hoverEnabled: true
                            cursorShape: enabled
                                ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.updateAyame()
                        }
                    }
                }
                }
            }
        }

        Rectangle {
            id: scrollTrack
            anchors {
                top: settingsFlickable.top
                bottom: settingsFlickable.bottom
                right: settingsFlickable.right
            }
            width: 4
            radius: Theme.radiusPill
            color: Theme.translucent(Theme.outlineVariant, 0.35)
            visible: settingsFlickable.interactive

            Rectangle {
                width: parent.width
                height: Math.max(40, parent.height
                    * settingsFlickable.height / settingsFlickable.contentHeight)
                y: settingsFlickable.contentY
                    / Math.max(1, settingsFlickable.contentHeight
                        - settingsFlickable.height)
                    * (parent.height - height)
                radius: Theme.radiusPill
                color: Theme.primary
            }
        }
    }

    WallpaperPickerPopup { id: wallpaperPicker; hostWindow: root.hostWindow }
    PaletteSetupPopup {
        id: paletteSetup
        hostWindow: root.hostWindow
        wallpaperPicker: wallpaperPicker
    }
    WeatherSetupPopup { id: weatherSetup; hostWindow: root.hostWindow }
}
