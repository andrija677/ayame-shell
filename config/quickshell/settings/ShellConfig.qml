pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property alias barEnabled: values.barEnabled
    property alias workspacesEnabled: values.workspacesEnabled
    property alias activeWindowEnabled: values.activeWindowEnabled
    property alias clockEnabled: values.clockEnabled
    property alias dashboardEnabled: values.dashboardEnabled
    property alias quickSettingsEnabled: values.quickSettingsEnabled
    property alias audioEnabled: values.audioEnabled
    property alias networkEnabled: values.networkEnabled
    property alias batteryEnabled: values.batteryEnabled
    property alias trayEnabled: values.trayEnabled
    property alias showPassiveTrayItems: values.showPassiveTrayItems
    property alias animationsEnabled: values.animationsEnabled
    property alias densityMode: values.densityMode
    property alias workspaceCount: values.workspaceCount

    function save() {
        saveTimer.restart();
    }

    function resetDefaults() {
        values.barEnabled = true;
        values.workspacesEnabled = true;
        values.activeWindowEnabled = true;
        values.clockEnabled = true;
        values.dashboardEnabled = true;
        values.quickSettingsEnabled = true;
        values.audioEnabled = true;
        values.networkEnabled = true;
        values.batteryEnabled = true;
        values.trayEnabled = true;
        values.showPassiveTrayItems = true;
        values.animationsEnabled = true;
        values.densityMode = "normal";
        values.workspaceCount = 5;
        save();
    }

    property Timer saveTimer: Timer {
        interval: 150
        onTriggered: settingsFile.writeAdapter()
    }

    property FileView settingsFile: FileView {
        id: settingsFile
        path: Quickshell.dataDir + "/settings.json"
        preload: true
        watchChanges: true
        atomicWrites: true
        printErrors: false

        onAdapterUpdated: root.save()

        JsonAdapter {
            id: values

            property bool barEnabled: true
            property bool workspacesEnabled: true
            property bool activeWindowEnabled: true
            property bool clockEnabled: true
            property bool dashboardEnabled: true
            property bool quickSettingsEnabled: true
            property bool audioEnabled: true
            property bool networkEnabled: true
            property bool batteryEnabled: true
            property bool trayEnabled: true
            property bool showPassiveTrayItems: true
            property bool animationsEnabled: true
            property string densityMode: "normal"
            property int workspaceCount: 5
        }
    }
}
