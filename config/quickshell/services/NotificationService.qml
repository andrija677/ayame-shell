pragma Singleton

import QtQuick
import Quickshell.Services.Notifications
import "../settings"

QtObject {
    id: root

    signal popupRequested(var notification)

    readonly property var server: serverLoader.item
    readonly property var notifications: server?.trackedNotifications ?? null
    readonly property int count: notifications?.values?.length ?? 0

    function clearAll() {
        // trackedNotifications is a live model. Dismissing an item mutates its
        // values array immediately, so iterate over a stable snapshot.
        const items = (notifications?.values ?? []).slice();
        for (let i = items.length - 1; i >= 0; --i) {
            items[i].dismiss();
            items[i].tracked = false;
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
                    if (!ShellConfig.doNotDisturb)
                        root.popupRequested(notification);
                }
            }
        }
    }
}
