import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../../components"
import "../../theme"

PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight + Theme.outerMargin
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

                Repeater {
                    model: 5

                    WorkspaceButton {
                        required property int index
                        workspaceId: index + 1
                        active: Hyprland.focusedWorkspace?.id === workspaceId
                        onActivated: Hyprland.dispatch("workspace " + workspaceId)
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

            Surface {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Theme.sideAreaWidth
                implicitHeight: Theme.itemHeight
                radius: Theme.radiusPill
                color: Theme.surfaceContainer

                StyledText {
                    anchors.centerIn: parent
                    text: SystemTray.items.values.length === 1
                        ? "1 tray item"
                        : SystemTray.items.values.length + " tray items"
                    color: Theme.foregroundSurfaceVariant
                    font.pixelSize: Theme.fontSmall
                }
            }
        }
    }
}
