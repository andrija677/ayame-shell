import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../theme"

Surface {
    id: root

    required property var notification
    signal dismissed()
    property bool exiting: false
    property bool dismissAfterExit: false
    property real exitProgress: 0
    readonly property var notificationData: notification?.payload ?? notification ?? ({
        appIcon: "", desktopEntry: "", summary: "", appName: "",
        body: "", actions: []
    })
    readonly property var visibleActions: {
        const actions = notificationData.actions || [];
        const visible = [];
        for (let i = 0; i < actions.length; ++i) {
            const action = actions[i];
            const label = (action?.text ?? "").trim();
            // The freedesktop notification specification permits a default
            // action with an empty label. It opens the notification's app or
            // associated content, so give it a useful label instead of
            // drawing an unexplained empty pill. Ignore any other malformed,
            // unlabeled actions.
            if (label.length > 0 || action?.identifier === "default")
                visible.push(action);
        }
        return visible;
    }
    readonly property var defaultAction: {
        const actions = notificationData.actions || [];
        for (let i = 0; i < actions.length; ++i) {
            if (actions[i]?.identifier === "default")
                return actions[i];
        }
        return null;
    }

    function actionText(action) {
        const label = (action?.text ?? "").trim();
        return label.length > 0 ? label.toUpperCase() : "OPEN";
    }

    function finishDismiss() {
        if (notification?.dismiss) {
            notification.dismiss();
        } else {
            notificationData?.dismiss?.();
            if (notificationData)
                notificationData.tracked = false;
        }
        dismissed();
    }

    function startExit(dismissAfter = false) {
        if (exiting)
            return;
        dismissAfterExit = dismissAfter;
        exiting = true;
        exitProgress = 1;
        if (dismissAfter)
            exitTimer.restart();
    }

    function dismissNotification() {
        startExit(true);
    }

    function openDefaultAction() {
        if (!defaultAction || exiting)
            return;
        defaultAction.invoke();
        dismissNotification();
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

    readonly property real expandedHeight: notificationContent.implicitHeight + Theme.space16
    implicitHeight: Math.max(0, expandedHeight * (1 - exitProgress))
    radius: Theme.radiusLarge
    color: Theme.translucent(Theme.surfaceContainer, 1 - exitProgress)
    border.width: 1
    border.color: Theme.translucent(Theme.outlineVariant, 0.45)
    clip: true

    transform: Translate {
        x: root.exitProgress * Theme.space24
    }

    Behavior on exitProgress {
        NumberAnimation {
            duration: Theme.motionNormal
            easing.type: Theme.easeExit
        }
    }

    Timer {
        id: exitTimer
        interval: Math.max(1, Theme.motionNormal)
        onTriggered: {
            if (root.dismissAfterExit)
                root.finishDismiss();
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.defaultAction !== null && !root.exiting
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.openDefaultAction()
    }

    ColumnLayout {
        id: notificationContent
        anchors { fill: parent; margins: Theme.space8 }
        spacing: Theme.space6
        opacity: 1 - root.exitProgress

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
                implicitWidth: 28
                implicitHeight: 28
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
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 4
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.visibleActions.length > 0
            spacing: Theme.space6

            Repeater {
                model: root.visibleActions

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
                        text: root.actionText(parent.modelData)
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
