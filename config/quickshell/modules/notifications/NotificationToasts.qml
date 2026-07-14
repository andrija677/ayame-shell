import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"

PanelWindow {
    id: root

    property var currentNotification: null
    property var queue: []
    property bool toastOpen: false
    readonly property var hyprlandMonitor: Hyprland.monitorFor(screen)

    function showNotification(notification) {
        if (currentNotification !== null) {
            queue = queue.concat([notification]);
            return;
        }
        currentNotification = notification;
        visible = true;
        toastOpen = true;
        expireTimer.interval = notification.urgency === NotificationUrgency.Critical
            ? 10000 : Math.max(4500, Math.min(8000, notification.expireTimeout || 6000));
        expireTimer.restart();
    }

    function closeToast() {
        if (!toastOpen)
            return;
        expireTimer.stop();
        toastOpen = false;
        closeTimer.restart();
    }

    anchors { top: true; right: true }
    margins { top: Theme.barHeight + Theme.outerMargin * 2; right: Theme.outerMargin }
    implicitWidth: 380
    implicitHeight: toastItem.implicitHeight
    exclusiveZone: 0
    color: "transparent"
    visible: false
    WlrLayershell.namespace: "ayame-shell-notification"
    WlrLayershell.layer: WlrLayer.Overlay

    Connections {
        target: NotificationService
        function onPopupRequested(notification) {
            if (Hyprland.focusedMonitor === root.hyprlandMonitor)
                root.showNotification(notification);
        }
    }

    Timer { id: expireTimer; onTriggered: root.closeToast() }
    Timer {
        id: closeTimer
        interval: Theme.motionNormal
        onTriggered: {
            root.visible = false;
            root.currentNotification = null;
            if (root.queue.length > 0) {
                const next = root.queue[0];
                root.queue = root.queue.slice(1);
                Qt.callLater(() => root.showNotification(next));
            }
        }
    }

    Connections {
        target: root.currentNotification
        function onClosed(reason) { root.closeToast(); }
    }

    NotificationItem {
        id: toastItem
        width: parent.width
        notification: root.currentNotification
        visible: root.currentNotification !== null
        opacity: root.toastOpen ? 1 : 0
        x: root.toastOpen ? 0 : Theme.space24
        onDismissed: root.closeToast()

        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }
        Behavior on x {
            NumberAnimation {
                duration: root.toastOpen ? Theme.motionSlow : Theme.motionNormal
                easing.type: root.toastOpen ? Theme.easeEnter : Theme.easeExit
            }
        }
    }
}
