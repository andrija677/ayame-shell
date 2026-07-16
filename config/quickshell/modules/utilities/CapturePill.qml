import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../../components"
import "../../services"
import "../../theme"

PanelWindow {
    id: root

    signal areaScreenshotRequested(int delay)
    signal areaRecordingRequested(string audio, int delay)

    property bool opened: false
    property string captureMode: "area"
    property string audioMode: "none"
    property int countdown: 0
    property int offsetX: 28
    property int offsetY: 110
    property real displayX: 0
    property real pointerOffsetX: 0
    property real pointerOffsetY: 0
    property string status: ""
    property string error: ""
    property bool suppressVisibility: false
    property bool closing: false
    property bool freeClosing: false
    property string snappedSide: ""
    property bool dragging: false
    readonly property real pillWidth: pillRow.implicitWidth + Theme.space16
    readonly property real pillHeight: pillRow.implicitHeight + Theme.space16

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
            displayX = -pillWidth - 4;
        else if (snappedSide === "right")
            displayX = width + 4;
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
        const right = Math.max(0, width - pillWidth);
        if (offsetX < 110) {
            offsetX = 0;
            snappedSide = "left";
        } else if (right - offsetX < 110) {
            offsetX = right;
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
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusiveZone: 0
    mask: Region { item: pillSurface }
    Behavior on displayX {
        enabled: !root.dragging
        SpringAnimation { spring: 3.2; damping: 0.32; epsilon: 0.35 }
    }
    WlrLayershell.namespace: "ayame-shell-capture-pill"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrLayershell.None

    ClippingRectangle {
        id: pillSurface
        x: root.displayX
        y: root.offsetY - (height - 48) / 2
        width: root.pillWidth
        height: root.pillHeight
        topLeftRadius: root.snappedSide === "left" ? 0 : Theme.radiusPill
        bottomLeftRadius: root.snappedSide === "left" ? 0 : Theme.radiusPill
        topRightRadius: root.snappedSide === "right" ? 0 : Theme.radiusPill
        bottomRightRadius: root.snappedSide === "right" ? 0 : Theme.radiusPill
        color: Theme.surface
        border.width: RecordingService.recording ? 2 : 1
        border.color: RecordingService.recording ? Theme.error : Theme.outlineVariant
        opacity: root.freeClosing ? 0 : 1
        scale: root.freeClosing ? 0.84 : 1
        Behavior on height { SpringAnimation { spring: 3; damping: 0.38 } }
        Behavior on width { SpringAnimation { spring: 3; damping: 0.38 } }
        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }
        Behavior on scale { NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeExit } }

        GridLayout {
            id: pillRow
            anchors.centerIn: parent
            columns: root.snappedSide.length > 0 ? 1 : 9
            rowSpacing: Theme.space4
            columnSpacing: Theme.space4

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
                        root.dragging = true;
                        const point = dragArea.mapToItem(root, mouse.x, mouse.y);
                        root.pointerOffsetX = point.x - root.offsetX;
                        root.pointerOffsetY = point.y - root.offsetY;
                    }
                    onPositionChanged: mouse => {
                        if (!pressed) return;
                        const point = dragArea.mapToItem(root, mouse.x, mouse.y);
                        root.offsetX = Math.max(0, Math.min(root.width - root.pillWidth,
                            point.x - root.pointerOffsetX));
                        root.offsetY = Math.max(0, Math.min(root.height - root.pillHeight,
                            point.y - root.pointerOffsetY));
                        root.displayX = root.offsetX;
                    }
                    onReleased: {
                        root.dragging = false;
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
                        else if (root.captureMode === "area") {
                            root.suppressVisibility = true;
                            root.areaRecordingRequested(root.audioMode, root.countdown);
                        } else
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

            StyledText {
                visible: RecordingService.error.length > 0
                Layout.maximumWidth: 180
                text: RecordingService.error
                color: Theme.error
                font.pixelSize: 9
                font.weight: Theme.fontWeightLabel
                elide: Text.ElideRight
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

    onPillWidthChanged: {
        if (snappedSide === "right" && !dragging) {
            offsetX = Math.max(0, width - pillWidth);
            displayX = offsetX;
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
