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

    Rectangle {
        anchors {
            fill: parent
            leftMargin: Theme.outerMargin
            rightMargin: Theme.outerMargin
            topMargin: Theme.outerMargin
        }
        radius: 12
        color: Theme.surface

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Theme.horizontalPadding
                rightMargin: Theme.horizontalPadding
            }
            spacing: Theme.itemSpacing

            Row {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 240
                spacing: Theme.itemSpacing

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

            Rectangle {
                Layout.alignment: Qt.AlignCenter
                implicitWidth: clockText.implicitWidth + Theme.horizontalPadding * 2
                implicitHeight: Theme.itemHeight
                radius: Theme.itemRadius
                color: Theme.surfaceRaised

                SystemClock {
                    id: clock
                    precision: SystemClock.Seconds
                }

                Text {
                    id: clockText
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Theme.textPrimary
                    font.family: "Noto Sans"
                    font.pixelSize: Theme.fontNormal
                    font.weight: Font.DemiBold
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 240
                implicitHeight: Theme.itemHeight
                radius: Theme.itemRadius
                color: Theme.surfaceRaised

                Text {
                    anchors.centerIn: parent
                    text: SystemTray.items.values.length + " tray"
                    color: Theme.textMuted
                    font.family: "Noto Sans"
                    font.pixelSize: Theme.fontSmall
                }
            }
        }
    }
}

