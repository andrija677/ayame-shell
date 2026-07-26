import QtQuick
import QtQuick.Layouts
import "../services"
import "../settings"
import "../theme"

Surface {
    id: root

    property bool clearing: false

    function clearWithAnimation() {
        if (clearing || NotificationService.count === 0)
            return;
        clearing = true;
        for (let i = 0; i < notificationRepeater.count; ++i) {
            const item = notificationRepeater.itemAt(i);
            if (item)
                item.startExit(false);
        }
        clearTimer.restart();
    }

    readonly property var recentNotifications: {
        NotificationService.count;
        const items = NotificationService.displayNotifications;
        return items.slice(Math.max(0, items.length - 3)).reverse();
    }

    Layout.fillWidth: true
    implicitHeight: notificationColumn.implicitHeight + Theme.space24
    color: Theme.surfaceContainer
    border.width: 1
    border.color: Theme.translucent(Theme.outlineVariant, 0.35)

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Theme.motionNormal
            easing.type: Theme.easeEnter
        }
    }

    Timer {
        id: clearTimer
        interval: Math.max(1, Theme.motionNormal)
        onTriggered: {
            NotificationService.clearAll();
            root.clearing = false;
        }
    }

    ColumnLayout {
        id: notificationColumn
        anchors { fill: parent; margins: Theme.space12 }
        spacing: Theme.space8

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "Notification Center"
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
                    enabled: !root.clearing
                    onClicked: root.clearWithAnimation()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 30
            radius: Theme.radiusPill
            color: dndPointer.containsMouse
                ? Theme.surfaceContainerHigh : Theme.surface
            RowLayout {
                anchors { fill: parent; leftMargin: Theme.space12; rightMargin: Theme.space12 }
                StyledText { text: "Do Not Disturb"; Layout.fillWidth: true }
                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 20
                    radius: Theme.radiusPill
                    color: ShellConfig.doNotDisturb
                        ? Theme.primary : Theme.outlineVariant
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: ShellConfig.doNotDisturb ? parent.width - width - 3 : 3
                        width: 14
                        height: 14
                        radius: 7
                        color: ShellConfig.doNotDisturb
                            ? Theme.foregroundPrimary
                            : Theme.foregroundSurfaceVariant
                        Behavior on x {
                            NumberAnimation {
                                duration: Theme.motionNormal
                                easing.type: Theme.easeEnter
                            }
                        }
                    }
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

        Item {
            Layout.fillWidth: true
            implicitHeight: 64
            visible: !ShellConfig.notificationServerEnabled
                || NotificationService.count === 0
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: Theme.space2
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: ShellConfig.notificationServerEnabled ? "✓" : "󰂛"
                    color: Theme.primary
                    font.pixelSize: 17
                    font.weight: Theme.fontWeightTitle
                }
                StyledText {
                    Layout.fillWidth: true
                    text: !ShellConfig.notificationServerEnabled
                        ? "Ayame notifications are disabled"
                        : "You're all caught up"
                    color: Theme.foregroundSurface
                    font.weight: Theme.fontWeightLabel
                    horizontalAlignment: Text.AlignHCenter
                }
                StyledText {
                    Layout.fillWidth: true
                    text: !ShellConfig.notificationServerEnabled
                        ? "Enable them from Ayame Settings"
                        : "New notifications will appear here"
                    color: Theme.foregroundSurfaceVariant
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }

        Repeater {
            id: notificationRepeater
            model: root.recentNotifications

            NotificationItem {
                required property var modelData
                Layout.fillWidth: true
                notification: modelData
            }
        }
    }
}
