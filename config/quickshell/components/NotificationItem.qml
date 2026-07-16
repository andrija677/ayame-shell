import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../theme"

Surface {
    id: root

    required property var notification
    signal dismissed()
    readonly property var notificationData: notification?.payload ?? notification ?? ({
        appIcon: "", desktopEntry: "", summary: "", appName: "",
        body: "", actions: []
    })
    readonly property var safeActions: notificationData.actions || []

    function dismissNotification() {
        if (notification?.dismiss) {
            notification.dismiss();
        } else {
            notificationData?.dismiss?.();
            if (notificationData)
                notificationData.tracked = false;
        }
        dismissed();
    }
    readonly property string resolvedIcon: {
        const icon = notificationData.appIcon || "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        if (icon.startsWith("file:"))
            return icon;
        if (icon.length > 0)
            return Quickshell.iconPath(icon, true);
        return Quickshell.iconPath(
            notificationData.desktopEntry || "dialog-information", true);
    }

    implicitHeight: notificationContent.implicitHeight + Theme.space24
    radius: Theme.radiusLarge
    color: Theme.surfaceContainer

    ColumnLayout {
        id: notificationContent
        anchors { fill: parent; margins: Theme.space12 }
        spacing: Theme.space6

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space8

            IconImage {
                implicitSize: 24
                source: root.resolvedIcon
                asynchronous: true
                mipmap: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                StyledText {
                    Layout.fillWidth: true
                    text: root.notificationData.summary
                    font.weight: Theme.fontWeightLabel
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.notificationData.appName
                    color: Theme.primary
                    font.pixelSize: 10
                    font.weight: Theme.fontWeightTitle
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                implicitWidth: 24
                implicitHeight: 24
                radius: Theme.radiusPill
                color: dismissPointer.containsMouse
                    ? Theme.surfaceContainerHigh : "transparent"
                StyledText {
                    anchors.centerIn: parent
                    text: "×"
                    color: Theme.foregroundSurfaceVariant
                    font.pixelSize: 16
                }
                MouseArea {
                    id: dismissPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dismissNotification()
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.notificationData.body
            color: Theme.foregroundSurfaceVariant
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.safeActions.length > 0
            spacing: Theme.space6

            Repeater {
                model: root.safeActions

                Rectangle {
                    required property var modelData
                    implicitWidth: actionLabel.implicitWidth + Theme.space16
                    implicitHeight: 28
                    radius: Theme.radiusPill
                    color: actionPointer.containsMouse
                        ? Theme.primary : Theme.primaryContainer
                    StyledText {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: parent.modelData.text.toUpperCase()
                        color: actionPointer.containsMouse
                            ? Theme.foregroundPrimary : Theme.foregroundPrimaryContainer
                        font.pixelSize: 9
                        font.weight: Theme.fontWeightTitle
                    }
                    MouseArea {
                        id: actionPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            parent.modelData.invoke();
                            root.dismissNotification();
                        }
                    }
                }
            }
        }
    }
}
