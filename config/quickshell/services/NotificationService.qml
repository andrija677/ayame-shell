pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../settings"

QtObject {
    id: root

    signal popupRequested(var notification)

    readonly property var server: serverLoader.item
    readonly property var notifications: server?.trackedNotifications ?? null
    readonly property var history: historyAdapter.entries ?? []
    readonly property int count: history.length
    readonly property var displayNotifications: {
        const liveItems = notifications?.values ?? [];
        const usedLive = [];
        return history.map(record => {
            let live = null;
            for (let i = liveItems.length - 1; i >= 0; --i) {
                const candidate = liveItems[i];
                if (usedLive.indexOf(i) < 0
                        && candidate.summary === record.summary
                        && candidate.appName === record.appName
                        && candidate.body === record.body) {
                    live = candidate;
                    usedLive.push(i);
                    break;
                }
            }
            return {
                historyId: record.id,
                payload: live ?? record,
                dismiss: () => root.dismissHistory(record.id, live)
            };
        });
    }

    function saveNotification(notification) {
        if (notification.transient === true)
            return;
        const updated = history.slice();
        updated.push({
            id: Date.now().toString() + "-" + Math.random().toString(16).slice(2),
            appIcon: notification.appIcon ?? "",
            desktopEntry: notification.desktopEntry ?? "",
            summary: notification.summary ?? "",
            appName: notification.appName ?? "",
            body: notification.body ?? "",
            receivedAt: new Date().toISOString(),
            actions: []
        });
        // Keep notification history useful without allowing its data file to
        // grow forever.
        historyAdapter.entries = updated.slice(Math.max(0, updated.length - 100));
        historyFile.writeAdapter();
    }

    function dismissHistory(historyId, liveNotification) {
        if (liveNotification) {
            liveNotification.dismiss();
            liveNotification.tracked = false;
        }
        historyAdapter.entries = history.filter(entry => entry.id !== historyId);
        historyFile.writeAdapter();
    }

    function clearAll() {
        // trackedNotifications is a live model. Dismissing an item mutates its
        // values array immediately, so iterate over a stable snapshot.
        const items = (notifications?.values ?? []).slice();
        for (let i = items.length - 1; i >= 0; --i) {
            items[i].dismiss();
            items[i].tracked = false;
        }
        historyAdapter.entries = [];
        historyFile.writeAdapter();
    }

    property FileView historyFile: FileView {
        id: historyFile
        path: Quickshell.dataDir + "/notification-history.json"
        preload: true
        atomicWrites: true
        printErrors: false

        JsonAdapter {
            id: historyAdapter
            property var entries: []
        }
    }

    property Loader serverLoader: Loader {
        active: ShellConfig.notificationServerEnabled

        sourceComponent: Component {
            NotificationServer {
                keepOnReload: true
                persistenceSupported: true
                bodySupported: true
                bodyMarkupSupported: false
                bodyHyperlinksSupported: false
                bodyImagesSupported: false
                actionsSupported: true
                actionIconsSupported: false
                imageSupported: true
                inlineReplySupported: false

                onNotification: notification => {
                    notification.tracked = true;
                    root.saveNotification(notification);
                    if (!ShellConfig.doNotDisturb)
                        root.popupRequested(notification);
                }
            }
        }
    }
}
