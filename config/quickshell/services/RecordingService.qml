pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool recording: false
    property string outputPath: ""
    property double startedAt: 0
    property int elapsedSeconds: 0
    readonly property string elapsedText: {
        const minutes = Math.floor(elapsedSeconds / 60).toString().padStart(2, "0");
        const seconds = (elapsedSeconds % 60).toString().padStart(2, "0");
        return minutes + ":" + seconds;
    }
    property string status: ""
    property string error: ""
    readonly property string script: Quickshell.shellDir + "/../../scripts/ayame-record.sh"

    function refresh() {
        if (!statusProcess.running)
            statusProcess.running = true;
    }

    function start(mode, audio, monitor, delay) {
        if (controlProcess.running || recording) return;
        error = "";
        status = mode === "area" ? "Select the recording area…" : "Starting recording…";
        controlProcess.command = [script, "start", mode, audio, monitor || "AUTO",
            (delay || 0).toString()];
        controlProcess.running = true;
    }

    function stop() {
        if (controlProcess.running || !recording) return;
        status = "Saving recording…";
        controlProcess.command = [script, "stop"];
        controlProcess.running = true;
    }

    property Process statusProcess: Process {
        id: statusProcess
        command: [root.script, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|");
                root.recording = parts[0] === "recording";
                root.outputPath = parts[1] ?? "";
                root.startedAt = Number(parts[2] ?? 0);
                if (parts[0] === "failed")
                    root.error = parts[1] || "Screen recording failed";
                root.elapsedSeconds = root.recording && root.startedAt > 0
                    ? Math.max(0, Math.floor(Date.now() / 1000 - root.startedAt)) : 0;
            }
        }
    }

    property Process controlProcess: Process {
        id: controlProcess
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    root.status = text.trim();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: root.error = text.trim()
        }
        onExited: (exitCode, exitStatus) => {
            refreshDelay.restart();
            if (exitCode !== 0 && root.error.length === 0)
                root.error = "Screen recording failed";
        }
    }

    property Timer refreshDelay: Timer {
        interval: 180
        onTriggered: root.refresh()
    }

    property Timer poller: Timer {
        interval: root.recording ? 500 : 1500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    property Timer elapsedTicker: Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.elapsedSeconds++
    }
}
