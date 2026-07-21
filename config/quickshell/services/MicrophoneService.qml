pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property var microphoneApps: []
    property var cameraApps: []
    readonly property bool active: microphoneApps.length > 0
    readonly property string appName: active ? microphoneApps[0] : ""
    readonly property int extraAppCount: Math.max(0, microphoneApps.length - 1)
    readonly property bool cameraActive: cameraApps.length > 0
    readonly property string cameraAppName: cameraActive ? cameraApps[0] : ""
    readonly property int extraCameraAppCount: Math.max(0, cameraApps.length - 1)

    function appLabel(props, fallback) {
        return props["application.name"]
            || props["application.process.binary"]
            || props["media.name"]
            || props["node.description"]
            || props["node.nick"]
            || props["node.name"]
            || fallback;
    }

    function uniqueRunningApps(objects, mediaClass, fallback) {
        const apps = [];
        for (const object of objects) {
            if (object?.type !== "PipeWire:Interface:Node"
                    || object.info?.state !== "running")
                continue;
            const props = object.info?.props ?? {};
            if (props["media.class"] !== mediaClass)
                continue;
            const label = appLabel(props, fallback);
            if (apps.indexOf(label) < 0)
                apps.push(label);
        }
        return apps;
    }

    function updateSnapshot(text) {
        try {
            const objects = JSON.parse(text);
            microphoneApps = uniqueRunningApps(
                objects, "Stream/Input/Audio", "Microphone"
            );
            cameraApps = uniqueRunningApps(
                objects, "Stream/Input/Video", "Camera"
            );
        } catch (error) {
            // Keep the previous good snapshot if PipeWire changes mid-dump.
        }
    }

    property Process snapshotProcess: Process {
        id: snapshotProcess
        command: ["pw-dump"]
        stdout: StdioCollector {
            onStreamFinished: root.updateSnapshot(text)
        }
    }

    property Timer refreshTimer: Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!snapshotProcess.running)
                snapshotProcess.running = true;
        }
    }
}
