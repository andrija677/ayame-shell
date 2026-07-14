pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool gameMode: false
    property bool gameModeBusy: false
    property bool networkingEnabled: true
    property bool networkingBusy: false
    readonly property string gameModeMarker: Quickshell.env("HOME")
        + "/.config/ml4w/settings/gamemode-enabled"
    readonly property string gameModeScript: Quickshell.env("HOME")
        + "/.config/hypr/scripts/gamemode.sh"

    function refreshGameMode() {
        if (statusProcess.running) return;
        statusProcess.running = true;
    }

    function toggleGameMode() {
        if (gameModeBusy) return;
        gameModeBusy = true;
        toggleProcess.command = [gameModeScript];
        toggleProcess.running = true;
    }

    function refreshNetworking() {
        if (!networkStatusProcess.running)
            networkStatusProcess.running = true;
    }

    function toggleNetworking() {
        if (networkingBusy) return;
        networkingBusy = true;
        networkToggleProcess.command = [
            "nmcli", "networking", networkingEnabled ? "off" : "on"
        ];
        networkToggleProcess.running = true;
    }

    property Process statusProcess: Process {
        id: statusProcess
        command: ["sh", "-c", "test -f \"$HOME/.config/ml4w/settings/gamemode-enabled\" && echo 1 || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: root.gameMode = text.trim() === "1"
        }
    }

    property Process toggleProcess: Process {
        id: toggleProcess
        onRunningChanged: {
            if (running) return;
            root.gameModeBusy = false;
            root.refreshGameMode();
        }
    }

    property Process networkStatusProcess: Process {
        id: networkStatusProcess
        command: ["nmcli", "networking"]
        stdout: StdioCollector {
            onStreamFinished: root.networkingEnabled = text.trim() === "enabled"
        }
    }

    property Process networkToggleProcess: Process {
        id: networkToggleProcess
        onRunningChanged: {
            if (running) return;
            root.networkingBusy = false;
            root.refreshNetworking();
        }
    }

    property Timer statusTimer: Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            root.refreshGameMode();
            root.refreshNetworking();
        }
    }
}
