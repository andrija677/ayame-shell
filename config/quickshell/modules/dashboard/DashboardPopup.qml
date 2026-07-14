import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../theme"

PopupWindow {
    id: root

    required property var hostWindow

    anchor.window: hostWindow
    anchor.rect.x: Math.round((hostWindow.width - width) / 2)
    anchor.rect.y: hostWindow.height
    implicitWidth: 420
    implicitHeight: dashboard.implicitHeight
    color: "transparent"
    grabFocus: true

    Surface {
        id: dashboard
        anchors {
            fill: parent
            topMargin: Theme.space8
        }
        implicitHeight: content.implicitHeight + Theme.space24
        radius: Theme.radiusLarge
        color: Theme.surface

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
                text: Qt.formatDateTime(new Date(), "dddd, d MMMM")
                font.pixelSize: Theme.fontTitle
                font.weight: Font.DemiBold
            }

            MediaCard { Layout.fillWidth: true }
            CalendarCard { Layout.fillWidth: true }

            Surface {
                Layout.fillWidth: true
                implicitHeight: 54
                color: Theme.surfaceContainer

                StyledText {
                    anchors.centerIn: parent
                    text: "Notifications will join when Ayame owns the session"
                    color: Theme.foregroundSurfaceVariant
                    font.pixelSize: Theme.fontSmall
                }
            }
        }
    }
}
