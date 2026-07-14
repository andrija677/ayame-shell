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

            Row {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Theme.sideAreaWidth
                spacing: Theme.space6
                visible: ShellConfig.workspacesEnabled

                Repeater {
                    model: ShellConfig.workspaceCount

                    WorkspaceButton {
                        required property int index
                        workspaceId: index + 1
                        active: Hyprland.focusedWorkspace?.id === workspaceId
                        // Hyprland 0.55 Lua configs require a Lua dispatcher
                        // expression instead of the legacy `workspace N` form.
                        onActivated: Hyprland.dispatch(
                            "hl.dsp.focus({ workspace = " + workspaceId + " })"
                        )
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Surface {
                Layout.alignment: Qt.AlignCenter
                implicitWidth: clockText.implicitWidth + Theme.space24
                implicitHeight: Theme.itemHeight
                radius: Theme.radiusPill
                color: Theme.surfaceContainerHigh
                visible: ShellConfig.clockEnabled

                SystemClock {
                    id: clock
                    precision: SystemClock.Seconds
                }

                StyledText {
                    id: clockText
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.pixelSize: Theme.fontNormal
                    font.weight: Font.DemiBold
                }
            }

            Item { Layout.fillWidth: true }

            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Theme.sideAreaWidth
                implicitHeight: Theme.itemHeight
                visible: ShellConfig.trayEnabled

                Surface {
                    anchors.right: parent.right
                    implicitWidth: Math.max(
                        Theme.itemHeight,
                        trayRow.implicitWidth + Theme.space8
                    )
                    implicitHeight: Theme.itemHeight
                    radius: Theme.radiusPill
                    color: Theme.surfaceContainer

                    Row {
                        id: trayRow
                        anchors.centerIn: parent
                        spacing: Theme.space2

                        Repeater {
                            model: SystemTray.items

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
