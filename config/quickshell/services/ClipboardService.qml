pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../settings"

QtObject {
    id: root

    property var entries: []
    property bool busy: false
    readonly property string script: Quickshell.shellDir
        + "/../../scripts/ayame-clipboard.sh"

    function refresh() {
        if (!ShellConfig.clipboardHistoryEnabled || listProcess.running) {
            if (!ShellConfig.clipboardHistoryEnabled) entries = [];
            return;
        }
        listProcess.running = true;
    }

    function run(action, id) {
        if (actionProcess.running) return;
        busy = true;
        actionProcess.command = id === undefined
            ? [script, action] : [script, action, String(id)];
        actionProcess.running = true;
    }

    function applyEnabled() {
        serviceProcess.command = ["systemctl", "--user",
            ShellConfig.clipboardHistoryEnabled ? "enable" : "disable",
            "--now", "ayame-clipboard.service"];
        serviceProcess.running = true;
        if (!ShellConfig.clipboardHistoryEnabled) entries = [];
    }

    property Process listProcess: Process {
        command: [root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                for (const line of text.trim().split("\n")) {
                    const fields = line.split("|");
                    if (fields.length >= 4)
                        result.push({ id: fields[0], kind: fields[1],
                            preview: fields[2], path: fields.slice(3).join("|") });
                }
                root.entries = result;
            }
        }
    }

    property Process actionProcess: Process {
        onRunningChanged: if (!running) { root.busy = false; root.refresh(); }
    }
    property Process serviceProcess: Process {
        onRunningChanged: if (!running && ShellConfig.clipboardHistoryEnabled)
            root.refresh()
    }
}
