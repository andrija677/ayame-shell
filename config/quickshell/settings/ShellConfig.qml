pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property alias barEnabled: values.barEnabled
    property alias dockEnabled: values.dockEnabled
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
    property alias dynamicColorsEnabled: values.dynamicColorsEnabled
    property alias dynamicColorMode: values.dynamicColorMode
    property alias dynamicColorWallpaper: values.dynamicColorWallpaper
    property alias dynamicColorStyle: values.dynamicColorStyle
    property alias workspaceCount: values.workspaceCount
    property alias weatherEnabled: values.weatherEnabled
    property alias weatherLocationName: values.weatherLocationName
    property alias weatherLatitude: values.weatherLatitude
    property alias weatherLongitude: values.weatherLongitude
    property alias weatherTemperatureUnit: values.weatherTemperatureUnit

    function save() {
        saveTimer.restart();
    }

    function resetDefaults() {
        values.barEnabled = true;
        values.dockEnabled = true;
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
        values.dynamicColorsEnabled = false;
        values.dynamicColorMode = "automatic";
        values.dynamicColorWallpaper = "";
        values.dynamicColorStyle = "tonal";
        values.workspaceCount = 5;
        values.weatherEnabled = false;
        values.weatherLocationName = "";
        values.weatherLatitude = 0;
        values.weatherLongitude = 0;
        values.weatherTemperatureUnit = "celsius";
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
            property bool dockEnabled: true
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
            property bool dynamicColorsEnabled: false
            property string dynamicColorMode: "automatic"
            property string dynamicColorWallpaper: ""
            property string dynamicColorStyle: "tonal"
            property int workspaceCount: 5
            property bool weatherEnabled: false
            property string weatherLocationName: ""
            property real weatherLatitude: 0
            property real weatherLongitude: 0
            property string weatherTemperatureUnit: "celsius"
        }
    }
}
