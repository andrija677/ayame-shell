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
    readonly property var emptyNotification: ({
        appIcon: "", desktopEntry: "", summary: "", appName: "",
        body: "", urgency: NotificationUrgency.Normal,
        expireTimeout: 6000, actions: []
    })
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
    margins {
        top: Theme.barHeight + Theme.outerMargin + Theme.space4
        right: Theme.outerMargin
    }
    implicitWidth: Math.min(440, screen.width - Theme.outerMargin * 2)
    implicitHeight: toastItem.implicitHeight
    exclusiveZone: -1
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false
    WlrLayershell.namespace: "ayame-shell-notification"
    WlrLayershell.layer: WlrLayer.Overlay

    Connections {
        target: NotificationService
        function onPopupRequested(notification) {
            const focusedName = Hyprland.focusedMonitor?.name ?? "";
            const ownName = root.hyprlandMonitor?.name ?? root.screen.name;
            if (Quickshell.screens.length === 1 || focusedName === ownName)
                root.showNotification(notification);
        }
        function onPopupsCleared() {
            expireTimer.stop();
            closeTimer.stop();
            root.queue = [];
            root.toastOpen = false;
            root.currentNotification = null;
            root.visible = false;
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

    NotificationItem {
        id: toastItem
        width: parent.width
        notification: root.currentNotification ?? root.emptyNotification
        bodyLineLimit: 3
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
