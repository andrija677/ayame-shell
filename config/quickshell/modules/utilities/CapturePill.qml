import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../components"
import "../../services"
import "../../theme"

PanelWindow {
    id: root

    signal areaScreenshotRequested(int delay)

    property bool opened: false
    property string captureMode: "area"
    property string audioMode: "none"
    property int countdown: 0
    property int offsetX: 28
    property int offsetY: 110
    property real displayX: 0
    property int offsetStartX: 0
    property int offsetStartY: 0
    property string status: ""
    property string error: ""
    property bool suppressVisibility: false
    property bool closing: false
    property bool freeClosing: false
    property string snappedSide: ""
    property bool dragging: false
    property bool dragInitialized: false
    property real cursorStartX: 0
    property real cursorStartY: 0

    function open() {
        freeClosing = false;
        closing = false;
        opened = true;
        displayX = offsetX;
    }
    function close() {
        if (RecordingService.recording || closing)
            return;
        closing = true;
        if (snappedSide === "left")
            displayX = 0;
        else if (snappedSide === "right")
            displayX = Math.max(0, screen.width - width);
        else
            freeClosing = true;
        closeTimer.restart();
    }
    function cycleMode() {
        captureMode = captureMode === "desktop" ? "monitor"
            : captureMode === "monitor" ? "area" : "desktop";
    }
    function cycleAudio() {
        audioMode = audioMode === "none" ? "system"
            : audioMode === "system" ? "microphone" : "none";
    }
    function cycleCountdown() {
        countdown = countdown === 0 ? 3 : countdown === 3 ? 5 : 0;
    }
    function snapIfNearEdge() {
        const right = Math.max(0, screen.width - width);
        if (offsetX < 110) {
            offsetX = 16;
            snappedSide = "left";
        } else if (right - offsetX < 110) {
            offsetX = Math.max(16, right - 16);
            snappedSide = "right";
        }
        displayX = offsetX;
    }
    function takeScreenshot() {
        if (screenshotProcess.running) return;
        status = "Capturing…";
        error = "";
        if (captureMode === "area") {
            suppressVisibility = true;
            areaScreenshotRequested(countdown);
            return;
        }
        screenshotHide.restart();
    }

    visible: (opened || RecordingService.recording || closing) && !suppressVisibility
    implicitWidth: pillRow.implicitWidth + Theme.space16
    implicitHeight: 48
    color: "transparent"
    exclusiveZone: 0
    anchors { top: true; left: true }
    margins { left: displayX; top: offsetY }
    Behavior on displayX {
        NumberAnimation { duration: Theme.motionSlow; easing.type: Theme.easeEnter }
    }
    WlrLayershell.namespace: "ayame-shell-capture-pill"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrLayershell.None

    Surface {
        id: pillSurface
        anchors.fill: parent
        radius: Theme.radiusPill
        color: Theme.surface
        border.width: RecordingService.recording ? 2 : 1
        border.color: RecordingService.recording ? Theme.error : Theme.outlineVariant
        opacity: root.freeClosing ? 0 : 1
        scale: root.freeClosing ? 0.84 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }
        Behavior on scale { NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeExit } }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: Theme.space4

            Rectangle {
                implicitWidth: 32; implicitHeight: 32
                radius: Theme.radiusPill
                color: dragArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                StyledText { anchors.centerIn: parent; text: "⠿"; color: Theme.outline; font.pixelSize: 15 }
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.SizeAllCursor
                    onPressed: mouse => {
                        root.snappedSide = "";
                        root.offsetStartX = root.offsetX;
                        root.offsetStartY = root.offsetY;
                        root.dragInitialized = false;
                        root.dragging = true;
                        cursorTracker.running = true;
                    }
                    onReleased: {
                        root.dragging = false;
                        root.dragInitialized = false;
                        root.snapIfNearEdge();
                    }
                }
            }

            Rectangle {
                implicitWidth: modeLabel.implicitWidth + Theme.space16
                implicitHeight: 32; radius: Theme.radiusPill
                color: modePointer.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                StyledText {
                    id: modeLabel; anchors.centerIn: parent
                    text: root.captureMode === "desktop" ? "Desktop"
                        : root.captureMode === "monitor" ? "Monitor" : "Area"
                    font.pixelSize: 10; font.weight: Theme.fontWeightLabel
                }
                MouseArea { id: modePointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleMode() }
            }

            Rectangle {
                implicitWidth: delayLabel.implicitWidth + Theme.space16
                implicitHeight: 32; radius: Theme.radiusPill
                color: delayPointer.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                StyledText {
                    id: delayLabel; anchors.centerIn: parent
                    text: root.countdown === 0 ? "Instant" : root.countdown + "s"
                    font.pixelSize: 10; font.weight: Theme.fontWeightLabel
                }
                MouseArea { id: delayPointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleCountdown() }
            }

            Rectangle {
                implicitWidth: 36; implicitHeight: 32; radius: Theme.radiusPill
                color: shotPointer.containsMouse ? Theme.primary : Theme.primaryContainer
                StyledText { anchors.centerIn: parent; text: "󰄀"; font.family: Theme.fontFamilyNumeric; font.pixelSize: 15 }
                MouseArea { id: shotPointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.takeScreenshot() }
            }

            Rectangle {
                implicitWidth: 36; implicitHeight: 32; radius: Theme.radiusPill
                color: RecordingService.recording ? Theme.error
                    : recordPointer.containsMouse ? Theme.primary : Theme.primaryContainer
                StyledText {
                    anchors.centerIn: parent
                    text: RecordingService.recording ? "■" : "●"
                    color: RecordingService.recording ? Theme.foregroundPrimary : Theme.error
                    font.pixelSize: RecordingService.recording ? 12 : 16
                }
                MouseArea {
                    id: recordPointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (RecordingService.recording)
                            RecordingService.stop();
                        else
                            RecordingService.start(root.captureMode, root.audioMode,
                                root.screen.name, root.countdown);
                    }
                }
            }

            Rectangle {
                implicitWidth: audioLabel.implicitWidth + Theme.space16
                implicitHeight: 32; radius: Theme.radiusPill
                color: audioPointer.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                StyledText {
                    id: audioLabel; anchors.centerIn: parent
                    text: root.audioMode === "none" ? "Silent"
                        : root.audioMode === "system" ? "System" : "Mic"
                    font.pixelSize: 10; font.weight: Theme.fontWeightLabel
                }
                MouseArea { id: audioPointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleAudio() }
            }

            StyledText {
                visible: RecordingService.recording
                text: RecordingService.elapsedText
                color: Theme.error
                font.family: Theme.fontFamilyNumeric
                font.pixelSize: 10
                font.weight: Theme.fontWeightTitle
            }

            Rectangle {
                visible: !RecordingService.recording
                implicitWidth: 30; implicitHeight: 30; radius: Theme.radiusPill
                color: closePointer.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                StyledText { anchors.centerIn: parent; text: "×"; font.pixelSize: 16 }
                MouseArea { id: closePointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
            }
        }
    }

    Timer {
        interval: 32
        repeat: true
        running: root.dragging
        onTriggered: {
            if (!cursorTracker.running)
                cursorTracker.running = true;
        }
    }
    Process {
        id: cursorTracker
        command: ["hyprctl", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/(-?\d+)\s*,\s*(-?\d+)/);
                if (!match || !root.dragging) return;
                const cursorX = Number(match[1]) - (root.screen?.x ?? 0);
                const cursorY = Number(match[2]) - (root.screen?.y ?? 0);
                if (!root.dragInitialized) {
                    root.cursorStartX = cursorX;
                    root.cursorStartY = cursorY;
                    root.dragInitialized = true;
                    return;
                }
                root.offsetX = Math.max(0, Math.min(root.screen.width - root.width,
                    root.offsetStartX + cursorX - root.cursorStartX));
                root.offsetY = Math.max(0, Math.min(root.screen.height - root.height,
                    root.offsetStartY + cursorY - root.cursorStartY));
                root.displayX = root.offsetX;
            }
        }
    }
    Timer {
        id: closeTimer
        interval: Theme.motionNormal + 30
        onTriggered: {
            root.opened = false;
            root.closing = false;
            root.freeClosing = false;
        }
    }
    Timer {
        id: screenshotHide
        interval: 160
        onTriggered: {
            root.suppressVisibility = true;
            screenshotStart.restart();
        }
    }
    Timer {
        id: screenshotStart
        interval: 120
        onTriggered: {
            screenshotProcess.command = [
                Quickshell.shellDir + "/../../scripts/ayame-screenshot.sh",
                root.captureMode, root.countdown.toString(), root.screen.name
            ];
            screenshotProcess.running = true;
        }
    }
    Process {
        id: screenshotProcess
        stdout: StdioCollector { onStreamFinished: root.status = text.trim() }
        stderr: StdioCollector { onStreamFinished: root.error = text.trim() }
        onExited: root.suppressVisibility = false
    }
}
