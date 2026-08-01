pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../settings"

QtObject {
    id: root
    readonly property string script: Quickshell.shellDir
        + "/../../scripts/ayame-system-controls.sh"
    property bool brightnessAvailable: false
    property bool keyboardBacklightAvailable: false
    property bool nightLightAvailable: false
    property bool idleAvailable: false
    property bool displaysAvailable: false
    property int brightness: 50
    property int keyboardBrightness: 0
    property var displays: []
    property bool ready: false

    function action(args) {
        actionProcess.command = [script].concat(args.map(value => String(value)));
        actionProcess.running = true;
    }
    function refresh() { if (!statusProcess.running) statusProcess.running = true; }
    function refreshDisplays() { if (!displayProcess.running) displayProcess.running = true; }
    function setBrightness(value) {
        brightness = Math.round(value);
        action(["brightness", brightness]);
    }
    function setKeyboardBrightness(value) {
        keyboardBrightness = Math.round(value);
        action(["keyboard", keyboardBrightness]);
    }
    function applyNightLight() {
        action(["nightlight", ShellConfig.nightLightEnabled ? 1 : 0,
            ShellConfig.nightLightTemperature]);
    }
    function applyIdle() {
        action(["idle", ShellConfig.idleEnabled ? 1 : 0,
            ShellConfig.idleTimeoutSeconds, ShellConfig.idleLockEnabled ? 1 : 0]);
    }

    property Process statusProcess: Process {
        command: [root.script, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const field = line.split("|");
                    if (field.length < 3) continue;
                    const available = field[1] === "1";
                    if (field[0] === "brightness") {
                        root.brightnessAvailable = available;
                        root.brightness = Number(field[2]);
                    } else if (field[0] === "keyboard") {
                        root.keyboardBacklightAvailable = available;
                        root.keyboardBrightness = Number(field[2]);
                    } else if (field[0] === "nightlight")
                        root.nightLightAvailable = available;
                    else if (field[0] === "idle") root.idleAvailable = available;
                    else if (field[0] === "display") root.displaysAvailable = available;
                }
                root.ready = true;
                root.refreshDisplays();
                if (root.nightLightAvailable && ShellConfig.nightLightEnabled)
                    root.applyNightLight();
                if (root.idleAvailable && ShellConfig.idleEnabled)
                    root.applyIdle();
            }
        }
    }
    property Process displayProcess: Process {
        command: [root.script, "displays"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                for (const line of text.trim().split("\n")) {
                    const field = line.split("|");
                    if (field.length >= 8)
                        result.push({ name: field[0], description: field[1],
                            width: Number(field[2]), height: Number(field[3]),
                            rate: Number(field[4]), scale: Number(field[5]),
                            x: Number(field[6]), y: Number(field[7]) });
                }
                root.displays = result;
            }
        }
    }
    // Values changed through Ayame are already reflected locally. Refreshing
    // after every action fed status back into applyNightLight()/applyIdle(),
    // continuously stopping and restarting their services.
    property Process actionProcess: Process {}
    property Timer startup: Timer {
        interval: 700; running: true
        onTriggered: root.refresh()
    }
}
