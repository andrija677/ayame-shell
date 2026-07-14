import QtQuick
import QtQuick.Layouts
import "../services"
import "../settings"
import "../theme"

Surface {
    id: root

    readonly property var recentNotifications: {
        NotificationService.count;
        const items = NotificationService.notifications?.values ?? [];
        return items.slice(Math.max(0, items.length - 3)).reverse();
    }

    Layout.fillWidth: true
    implicitHeight: notificationColumn.implicitHeight + Theme.space24
    color: Theme.surfaceContainer

    ColumnLayout {
        id: notificationColumn
        anchors { fill: parent; margins: Theme.space12 }
        spacing: Theme.space8

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "Notifications"
                font.pixelSize: Theme.fontTitle
                font.weight: Theme.fontWeightLabel
                Layout.fillWidth: true
            }
            StyledText {
                visible: NotificationService.count > 0
                text: "Clear All"
                color: clearPointer.containsMouse ? Theme.primary : Theme.outline
                font.pixelSize: 9
                font.weight: Theme.fontWeightTitle
                MouseArea {
                    id: clearPointer
                    anchors { fill: parent; margins: -Theme.space8 }
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.clearAll()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 34
            radius: Theme.radiusPill
            color: dndPointer.containsMouse
                ? Theme.surfaceContainerHigh : Theme.surface
            RowLayout {
                anchors { fill: parent; leftMargin: Theme.space12; rightMargin: Theme.space12 }
                StyledText { text: "Do Not Disturb"; Layout.fillWidth: true }
                StyledText {
                    text: ShellConfig.doNotDisturb ? "ON" : "OFF"
                    color: ShellConfig.doNotDisturb ? Theme.primary : Theme.outline
                    font.pixelSize: 10
                    font.weight: Theme.fontWeightTitle
                }
            }
            MouseArea {
                id: dndPointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellConfig.doNotDisturb = !ShellConfig.doNotDisturb
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: !ShellConfig.notificationServerEnabled
                || NotificationService.count === 0
            text: !ShellConfig.notificationServerEnabled
                ? "Enable Ayame notifications in Settings when it owns the session"
                : "You're all caught up"
            color: Theme.foregroundSurfaceVariant
            font.pixelSize: Theme.fontSmall
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: root.recentNotifications

            NotificationItem {
                required property var modelData
                Layout.fillWidth: true
                notification: modelData
            }
        }
    }
}
