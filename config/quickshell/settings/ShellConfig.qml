pragma Singleton

import QtQuick

QtObject {
    // These defaults are intentionally kept in one place. A later settings
    // service and graphical settings panel will manage persistent overrides.
    readonly property bool barEnabled: true
    readonly property bool workspacesEnabled: true
    readonly property bool activeWindowEnabled: true
    readonly property bool clockEnabled: true
    readonly property bool audioEnabled: true
    readonly property bool networkEnabled: true
    readonly property bool batteryEnabled: true
    readonly property bool trayEnabled: true
    readonly property bool showPassiveTrayItems: true

    readonly property int workspaceCount: 5
}
