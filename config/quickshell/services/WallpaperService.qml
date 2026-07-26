pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../settings"

QtObject {
    id: root
    property string error: ""
    property bool applying: false
    property string sourcePath: ""
    property string pendingPath: ""
    readonly property string defaultWallpaper:
        Quickshell.shellDir + "/../../assets/wallpapers/ayame-default.jpg"

    function apply(path) {
        const clean = (path || "").trim();
        if (clean.length === 0) return;
        ShellConfig.dynamicColorWallpaper = clean;
        if (setter.running) {
            pendingPath = clean;
            applying = true;
            return;
        }
        error = "";
        applying = true;
        sourcePath = clean;
        setter.command = [Quickshell.shellDir + "/../../scripts/ayame-wallpaper.sh", "set", clean];
        setter.running = true;
    }

    property Process setter: Process {
        id: setter
        stderr: StdioCollector {
            onStreamFinished: root.error = text.trim()
        }
        onRunningChanged: {
            if (running) return;
            if (root.pendingPath.length > 0
                    && root.pendingPath !== root.sourcePath) {
                root.queuedPath = root.pendingPath;
                root.pendingPath = "";
                queuedApply.restart();
                return;
            }
            root.pendingPath = "";
            root.applying = false;
        }
    }

    property string queuedPath: ""
    property Timer queuedApply: Timer {
        interval: 1
        onTriggered: {
            const path = root.queuedPath;
            root.queuedPath = "";
            root.apply(path);
        }
    }

    property Timer restoreTimer: Timer {
        interval: 1400
        running: true
        onTriggered: root.apply(ShellConfig.dynamicColorWallpaper.length > 0
            ? ShellConfig.dynamicColorWallpaper : root.defaultWallpaper)
    }
}
