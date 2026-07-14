import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"

PopupWindow {
    id: root

    required property var hostWindow
    property bool panelOpen: false

    function openPanel() {
        closeTimer.stop();
        visible = true;
        panelOpen = true;
    }

    function closePanel() {
        panelOpen = false;
        closeTimer.restart();
    }

    anchor.window: hostWindow
    anchor.rect.x: hostWindow.width - width - Theme.outerMargin
    anchor.rect.y: hostWindow.height
    implicitWidth: 460
    implicitHeight: settingsSurface.implicitHeight + Theme.space8
    color: "transparent"
    grabFocus: false
    visible: false

    onVisibleChanged: {
        if (!visible) {
            closeTimer.stop();
            panelOpen = false;
        }
    }

    Timer {
        id: closeTimer
        interval: Theme.motionNormal
        onTriggered: root.visible = false
    }

    Surface {
        id: settingsSurface
        width: parent.width
        implicitHeight: content.implicitHeight + Theme.space24
        y: root.panelOpen ? Theme.space8 : -Theme.space4
        opacity: root.panelOpen ? 1 : 0
        radius: Theme.radiusLarge
        color: Theme.surface

        transform: Scale {
            origin.x: settingsSurface.width
            origin.y: 0
            xScale: root.panelOpen ? 1 : 0.94
            yScale: root.panelOpen ? 1 : 0.88
            Behavior on xScale {
                NumberAnimation {
                    duration: root.panelOpen ? Theme.motionSlow : Theme.motionNormal
                    easing.type: root.panelOpen ? Theme.easeEnter : Theme.easeExit
                }
            }
            Behavior on yScale {
                NumberAnimation {
                    duration: root.panelOpen ? Theme.motionSlow : Theme.motionNormal
                    easing.type: root.panelOpen ? Theme.easeEnter : Theme.easeExit
                }
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: root.panelOpen ? Theme.motionSlow : Theme.motionNormal
                easing.type: root.panelOpen ? Theme.easeEnter : Theme.easeExit
            }
        }
        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }

        ColumnLayout {
            id: content
            anchors { fill: parent; margins: Theme.space12 }
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
                    text: "CLOSE"
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
                text: "APPEARANCE"
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
                            { label: "DARK", value: "dark" },
                            { label: "LIGHT", value: "light" }
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
                                onClicked: ShellConfig.colorScheme = parent.modelData.value
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
                        implicitWidth: 66
                        implicitHeight: 28
                        radius: Theme.radiusPill
                        color: palettePointer.containsMouse ? Theme.primary : Theme.primaryContainer
                        StyledText {
                            anchors.centerIn: parent
                            text: "CHANGE"
                            color: palettePointer.containsMouse
                                ? Theme.foregroundPrimary : Theme.foregroundPrimaryContainer
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
                text: "SHELL LAYOUT"
                color: Theme.primary
                font.pixelSize: 10
                font.weight: Theme.fontWeightTitle
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
                text: "SERVICES"
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
        }
    }

    PaletteSetupPopup { id: paletteSetup; hostWindow: root.hostWindow }
    WeatherSetupPopup { id: weatherSetup; hostWindow: root.hostWindow }
}
