pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../settings"

QtObject {
    id: root

    signal popupRequested(var notification)
    signal popupsCleared()

    readonly property var server: serverLoader.item
    readonly property var notifications: server?.trackedNotifications ?? null
    readonly property var history: historyAdapter.entries ?? []
    readonly property int count: history.length
    // History cards use immutable records. Native notification objects can be
    // destroyed at any time by their client and must not be retained by UI.
    readonly property var displayNotifications: history.map(record => ({
        historyId: record.id,
        payload: record,
        dismiss: () => root.dismissHistory(record.id)
    }))

    function popupSnapshot(notification) {
        const actions = [];
        for (const action of notification.actions ?? []) {
            const nativeAction = action;
            actions.push({
                identifier: action.identifier ?? "",
                text: action.text ?? "",
                invoke: () => {
                    try { nativeAction.invoke(); } catch (error) { }
                }
            });
        }
        return {
            appIcon: notification.appIcon ?? "",
            desktopEntry: notification.desktopEntry ?? "",
            summary: notification.summary ?? "",
            appName: notification.appName ?? "",
            body: notification.body ?? "",
            urgency: notification.urgency,
            expireTimeout: notification.expireTimeout ?? 6000,
            actions: actions
        };
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

    function dismissHistory(historyId) {
        historyAdapter.entries = history.filter(entry => entry.id !== historyId);
        historyFile.writeAdapter();
    }

    function clearAll() {
        // Saved history and transient popup state belong to Ayame. Do not
        // mutate the server's live native objects here: clients may still own
        // them, and untracking the entire model can disrupt future delivery.
        historyAdapter.entries = [];
        historyFile.writeAdapter();
        popupsCleared();
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
                        root.popupRequested(root.popupSnapshot(notification));
                }
            }
        }
    }
}
