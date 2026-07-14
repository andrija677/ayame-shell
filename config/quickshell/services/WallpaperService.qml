pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../settings"

QtObject {
    id: root
    property string error: ""
    property bool applying: false
    readonly property string defaultWallpaper:
        Quickshell.shellDir + "/../../assets/wallpapers/ayame-default.jpg"

    function apply(path) {
        const clean = (path || "").trim();
        if (clean.length === 0 || setter.running) return;
        error = "";
        applying = true;
        ShellConfig.dynamicColorWallpaper = clean;
        setter.command = [Quickshell.shellDir + "/../../scripts/ayame-wallpaper.sh", "set", clean];
        setter.running = true;
    }

    property Process setter: Process {
        id: setter
        stderr: StdioCollector {
            onStreamFinished: root.error = text.trim()
        }
        onRunningChanged: {
            if (!running) root.applying = false;
        }
    }

    property Timer restoreTimer: Timer {
        interval: 1400
        running: true
        onTriggered: root.apply(ShellConfig.dynamicColorWallpaper.length > 0
            ? ShellConfig.dynamicColorWallpaper : root.defaultWallpaper)
    }
}
