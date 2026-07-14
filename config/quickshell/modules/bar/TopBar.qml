import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../../components"
import "../../settings"
import "../../theme"

PanelWindow {
    id: bar

    readonly property var hyprlandMonitor: Hyprland.monitorFor(screen)

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight + Theme.outerMargin
    visible: ShellConfig.barEnabled
    color: "transparent"
    exclusiveZone: implicitHeight

    Surface {
        anchors {
            fill: parent
            leftMargin: Theme.outerMargin
            rightMargin: Theme.outerMargin
            topMargin: Theme.outerMargin
        }
        radius: Theme.radiusLarge
        color: Theme.surface

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Theme.space12
                rightMargin: Theme.space12
            }
            spacing: Theme.space6

            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Theme.sideAreaWidth
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
                        model: ShellConfig.workspaceCount

                        WorkspaceButton {
                            required property int index
                            workspaceId: index + 1
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
                Layout.alignment: Qt.AlignCenter
                visible: ShellConfig.clockEnabled
            }

            Item { Layout.fillWidth: true }

            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Theme.sideAreaWidth
                implicitHeight: Theme.itemHeight
                visible: ShellConfig.audioEnabled
                    || ShellConfig.networkEnabled
                    || ShellConfig.batteryEnabled
                    || ShellConfig.trayEnabled

                Surface {
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
                        }

                        BatteryIndicator {
                            visible: ShellConfig.batteryEnabled && available
                        }

                        Repeater {
                            model: ShellConfig.trayEnabled ? SystemTray.items : null

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
