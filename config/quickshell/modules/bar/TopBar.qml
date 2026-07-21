import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"
import "../dashboard"
import "../quicksettings"
import "../power"
import "../notifications"
import "../utilities"

PanelWindow {
    id: bar

    required property var shellController

    readonly property var hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property int activeWorkspaceId:
        Math.max(1, hyprlandMonitor?.activeWorkspace?.id || 1)
    readonly property int workspacePageStart: activeWorkspaceId <= 5 ? 1
        : 6 + Math.floor((activeWorkspaceId - 6) / 6) * 6
    readonly property int workspacePageSize: workspacePageStart === 1 ? 5 : 6
    readonly property int balancedSideWidth: Math.max(240,
        Math.min(560, Math.floor((width - 320) / 2)))
    property bool trayExpanded: false
    property real recordingProgress: RecordingService.recording ? 1 : 0

    Behavior on recordingProgress {
        NumberAnimation {
            duration: Theme.motionSlow
            easing.type: Easing.InOutCubic
        }
    }

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
        + (ShellConfig.barStyle === "floating" ? Theme.outerMargin : 0)
    visible: ShellConfig.barEnabled
    color: "transparent"
    exclusiveZone: implicitHeight
    WlrLayershell.namespace: "ayame-shell-bar"

    Surface {
        anchors {
            fill: parent
            leftMargin: ShellConfig.barStyle === "floating" ? Theme.outerMargin : 0
            rightMargin: ShellConfig.barStyle === "floating" ? Theme.outerMargin : 0
            topMargin: ShellConfig.barStyle === "floating" ? Theme.outerMargin : 0
        }
        radius: ShellConfig.barStyle === "floating" ? Theme.radiusLarge : 0
        color: ShellConfig.barStyle === "minimal" ? "transparent" : Theme.surface

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Theme.space12
                rightMargin: Theme.space12
            }
            spacing: Theme.space6

            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: bar.balancedSideWidth
                implicitHeight: Theme.itemHeight
                visible: ShellConfig.workspacesEnabled
                    || ShellConfig.activeWindowEnabled

                Row {
                    id: workspaceRow
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.space6
                    visible: ShellConfig.workspacesEnabled

                    Repeater {
                        model: bar.workspacePageSize

                        WorkspaceButton {
                            required property int index
                            workspaceId: bar.workspacePageStart + index
                            active: bar.hyprlandMonitor?.activeWorkspace?.id
                                === workspaceId
                            // Hyprland 0.55 Lua configs require a Lua dispatcher
                            // expression instead of the legacy `workspace N` form.
                            onActivated: Hyprland.dispatch(
                                "hl.dsp.focus({ workspace = " + workspaceId + " })"
                            )
                        }
                    }
                }

                ActiveWindowTitle {
                    anchors {
                        left: workspaceRow.visible
                            ? workspaceRow.right
                            : parent.left
                        leftMargin: workspaceRow.visible ? Theme.space12 : 0
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    visible: ShellConfig.activeWindowEnabled
                        && Hyprland.focusedMonitor === bar.hyprlandMonitor
                        && windowTitle.length > 0
                }
            }

            Item { Layout.fillWidth: true }

            ClockPill {
                id: clockPill
                Layout.alignment: Qt.AlignCenter
                visible: ShellConfig.clockEnabled
                expanded: dashboard.open
                onActivated: {
                    if (!ShellConfig.dashboardEnabled)
                        return;
                    if (weatherIndicator.open)
                        weatherIndicator.closePanel();
                    if (quickSettings.open)
                        quickSettings.closePanel();
                    dashboard.toggle();
                }
            }

            Item { Layout.fillWidth: true }

            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: bar.balancedSideWidth
                implicitHeight: Theme.itemHeight
                visible: ShellConfig.audioEnabled
                    || ShellConfig.networkEnabled
                    || ShellConfig.batteryEnabled
                    || ShellConfig.quickSettingsEnabled
                    || ShellConfig.trayEnabled

                Surface {
                    anchors {
                        right: privacyIndicators.left
                        rightMargin: Theme.space8 * bar.recordingProgress
                        verticalCenter: parent.verticalCenter
                    }
                    visible: bar.recordingProgress > 0.001
                    implicitWidth: (recordingLabel.implicitWidth + Theme.space16)
                        * bar.recordingProgress
                    implicitHeight: Theme.itemHeight
                    radius: Theme.radiusPill
                    color: Theme.error
                    opacity: bar.recordingProgress
                    scale: 0.9 + 0.1 * bar.recordingProgress
                    clip: true

                    StyledText {
                        id: recordingLabel
                        anchors.centerIn: parent
                        text: "●  " + RecordingService.elapsedText
                        color: Theme.foregroundPrimary
                        font.family: Theme.fontFamilyNumeric
                        font.pixelSize: 10
                        font.weight: Theme.fontWeightTitle
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: RecordingService.stop()
                    }
                }

                Row {
                    id: privacyIndicators
                    anchors {
                        right: systemPill.left
                        rightMargin: Theme.space8
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: Theme.space4

                    MicrophoneIndicator { hostWindow: bar }
                    CameraIndicator { hostWindow: bar }
                }

                Surface {
                    id: systemPill
                    anchors.right: parent.right
                    implicitWidth: Math.max(
                        Theme.itemHeight,
                        systemRow.implicitWidth + Theme.space8
                    )
                    implicitHeight: Theme.itemHeight
                    radius: Theme.radiusPill
                    color: Theme.surfaceContainer

                    Row {
                        id: systemRow
                        anchors.centerIn: parent
                        spacing: Theme.space2

                        AudioControl {
                            visible: ShellConfig.audioEnabled
                        }

                        NetworkIndicator {
                            visible: ShellConfig.networkEnabled
                            hostWindow: bar
                            onQuickSettingsRequested: quickSettings.openPanel()
                        }

                        WeatherIndicator {
                            id: weatherIndicator
                            visible: ShellConfig.weatherEnabled
                            hostWindow: bar
                        }

                        BatteryIndicator {
                            visible: ShellConfig.batteryEnabled && available
                        }

                        QuickSettingsButton {
                            visible: ShellConfig.quickSettingsEnabled
                            active: quickSettings.open
                            onActivated: {
                                if (weatherIndicator.open)
                                    weatherIndicator.closePanel();
                                if (dashboard.open)
                                    dashboard.closePanel();
                                quickSettings.toggle();
                            }
                        }

                        Rectangle {
                            visible: ShellConfig.trayEnabled
                                && SystemTray.items.values.length > 0
                            implicitWidth: Theme.itemHeight
                            implicitHeight: Theme.itemHeight
                            radius: Theme.radiusPill
                            color: trayTogglePointer.containsMouse
                                ? Theme.surfaceContainerHigh : "transparent"
                            scale: trayTogglePointer.pressed ? 0.9 : 1

                            Behavior on color {
                                ColorAnimation { duration: Theme.motionFast }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: Theme.motionFast
                                    easing.type: Theme.easeEnter
                                }
                            }

                            StyledText {
                                anchors.centerIn: parent
                                text: bar.trayExpanded ? "⌃" : "•••"
                                color: bar.trayExpanded
                                    ? Theme.primary : Theme.foregroundSurfaceVariant
                                font.pixelSize: bar.trayExpanded ? 15 : 10
                                font.weight: Theme.fontWeightTitle
                            }

                            MouseArea {
                                id: trayTogglePointer
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bar.trayExpanded = !bar.trayExpanded
                            }
                        }

                        Item {
                            visible: ShellConfig.trayEnabled
                                && SystemTray.items.values.length > 0
                            width: bar.trayExpanded ? trayItemsRow.implicitWidth : 0
                            height: Theme.itemHeight
                            opacity: bar.trayExpanded ? 1 : 0
                            clip: true

                            Behavior on width {
                                NumberAnimation {
                                    duration: Theme.motionNormal
                                    easing.type: bar.trayExpanded
                                        ? Theme.easeEnter : Theme.easeExit
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation { duration: Theme.motionFast }
                            }

                            Row {
                                id: trayItemsRow
                                height: parent.height
                                spacing: Theme.space2

                                Repeater {
                                    model: ShellConfig.trayEnabled
                                        ? SystemTray.items : null

                                    TrayItemButton {
                                        required property var modelData
                                        trayItem: modelData
                                        hostWindow: bar
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    DashboardPopup {
        id: dashboard
        hostWindow: bar
        visible: false
    }

    QuickSettingsPopup {
        id: quickSettings
        hostWindow: bar
        visible: false
        onPowerRequested: powerScreen.openPanel()
        onUtilityRequested: page => {
            if (page === "capture")
                utilities.openCapturePill();
            else
                utilities.openPage(page);
        }
    }

    PowerScreen {
        id: powerScreen
        screen: bar.screen
    }

    NotificationToasts { screen: bar.screen }

    UtilitiesScreen {
        id: utilities
        screen: bar.screen
    }

    Connections {
        target: bar.shellController
        function onAreaCaptureRequested() {
            if (Hyprland.focusedMonitor === bar.hyprlandMonitor)
                utilities.startAreaScreenshot(0);
        }
    }
}
