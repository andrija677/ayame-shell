import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../components"
import "../../theme"

PanelWindow {
    id: root

    property bool panelOpen: false
    property string page: "keys"
    property string captureMode: "area"
    property int captureDelay: 0
    property int titleClicks: 0
    property bool easterEggOpen: false
    property string status: ""
    property string captureError: ""
    property bool selectionMode: false
    property real selectionStartX: 0
    property real selectionStartY: 0
    property real selectionCurrentX: 0
    property real selectionCurrentY: 0
    property bool selectionDragging: false
    readonly property var bindings: [
        { keys: "SUPER", action: "Open launcher when released" },
        { keys: "SUPER + ENTER", action: "Open Kitty terminal" },
        { keys: "CTRL + ALT + T", action: "Open Kitty (VM fallback)" },
        { keys: "SUPER + 1…5", action: "Switch workspace" },
        { keys: "SUPER + SHIFT + 1…5", action: "Move window to workspace" },
        { keys: "SUPER + F", action: "Toggle fullscreen" },
        { keys: "SUPER + SHIFT + F", action: "Toggle floating / unlock window" },
        { keys: "SUPER + LEFT DRAG", action: "Move a floating window anywhere" },
        { keys: "SUPER + RIGHT DRAG", action: "Resize a floating window" },
        { keys: "SUPER + Q", action: "Close the active window" },
        { keys: "PRINT", action: "Capture the full desktop" },
        { keys: "SHIFT + PRINT", action: "Select an area to capture" },
        { keys: "SUPER + PRINT", action: "Capture the active monitor" },
        { keys: "SUPER + SHIFT + R", action: "Start or stop screen recording" }
    ]

    function openCapturePill() {
        closePanel();
        capturePill.open();
    }

    function openPage(targetPage) {
        closeTimer.stop();
        page = targetPage;
        status = "";
        visible = true;
        panelOpen = true;
    }

    function closePanel() {
        panelOpen = false;
        easterEggOpen = false;
        closeTimer.restart();
    }

    function capture() {
        if (captureProcess.running || captureStartTimer.running)
            return;
        status = captureDelay > 0 ? "Capturing in " + captureDelay + " seconds…" : "Capturing…";
        captureError = "";
        panelOpen = false;
        visible = false;
        if (captureMode === "area") {
            captureStartTimer.interval = 220 + captureDelay * 1000;
        } else {
            captureStartTimer.interval = 220;
            captureProcess.command = [
                Quickshell.shellDir + "/../../scripts/ayame-screenshot.sh",
                captureMode, captureDelay.toString(), screen.name
            ];
        }
        captureStartTimer.restart();
    }

    function finishSelection() {
        const left = Math.round(Math.min(selectionStartX, selectionCurrentX));
        const top = Math.round(Math.min(selectionStartY, selectionCurrentY));
        const width = Math.round(Math.abs(selectionCurrentX - selectionStartX));
        const height = Math.round(Math.abs(selectionCurrentY - selectionStartY));
        if (width < 2 || height < 2) {
            selectionMode = false;
            visible = false;
            capturePill.suppressVisibility = false;
            capturePill.open();
            return;
        }
        const geometry = left + "," + top + " " + width + "x" + height;
        captureProcess.command = [
            Quickshell.shellDir + "/../../scripts/ayame-screenshot.sh",
            "geometry", "0", geometry
        ];
        selectionMode = false;
        visible = false;
        captureAfterSelection.restart();
    }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false
    WlrLayershell.namespace: "ayame-shell-utilities"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: panelOpen || selectionMode
        ? WlrLayershell.OnDemand : WlrLayershell.None

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.selectionMode) {
                root.selectionDragging = false;
                root.selectionMode = false;
                root.visible = false;
                capturePill.suppressVisibility = false;
                capturePill.open();
            } else {
                root.closePanel();
            }
        }
    }
    Timer {
        id: closeTimer
        interval: Theme.motionNormal + Theme.motionUnmapGrace
        onTriggered: root.visible = false
    }
    Timer {
        id: captureStartTimer
        interval: 220
        onTriggered: {
            if (root.captureMode === "area") {
                root.selectionDragging = false;
                root.visible = true;
                root.selectionMode = true;
            } else {
                captureProcess.running = true;
            }
        }
    }
    Timer { id: captureAfterSelection; interval: 140; onTriggered: captureProcess.running = true }
    Timer {
        interval: 40
        repeat: true
        running: root.selectionDragging
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
                if (match && root.selectionDragging) {
                    const offsetX = root.screen && root.screen.x !== undefined
                        ? root.screen.x : 0;
                    const offsetY = root.screen && root.screen.y !== undefined
                        ? root.screen.y : 0;
                    root.selectionCurrentX = Number(match[1]) - offsetX;
                    root.selectionCurrentY = Number(match[2]) - offsetY;
                }
            }
        }
    }

    Process {
        id: captureProcess
        stdout: StdioCollector {
            onStreamFinished: root.status = text.trim().length > 0
                ? "Saved to " + text.trim() : "Capture cancelled"
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    root.captureError = text.trim();
            }
        }
        onExited: (exitCode, exitStatus) => {
            capturePill.suppressVisibility = false;
            if (capturePill.opened)
                capturePill.open();
            if (exitCode !== 0 || root.captureError.length > 0) {
                const failure = root.captureError.length > 0
                    ? root.captureError : "Screenshot failed. Check that grim and slurp can access this session.";
                Qt.callLater(() => {
                    root.openPage("capture");
                    root.status = failure;
                });
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        opacity: root.panelOpen ? 0.72 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }
    }
    MouseArea { anchors.fill: parent; enabled: root.panelOpen; onClicked: root.closePanel() }

    Surface {
        anchors.centerIn: parent
        width: Math.min(680, root.width - Theme.space24 * 2)
        implicitHeight: utilityContent.implicitHeight + Theme.space24
        radius: Theme.radiusLarge
        color: Theme.surface
        opacity: root.panelOpen ? 1 : 0
        scale: root.panelOpen ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }
        Behavior on scale { NumberAnimation { duration: Theme.motionSlow; easing.type: Theme.easeEnter } }

        ColumnLayout {
            id: utilityContent
            anchors { fill: parent; margins: Theme.space12 }
            spacing: Theme.space12

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: root.page === "keys" ? "Keybinds" : "Screenshot"
                    font.pixelSize: 24
                    font.weight: Theme.fontWeightDisplay
                    Layout.fillWidth: true
                    MouseArea {
                        anchors { fill: parent; margins: -Theme.space8 }
                        onClicked: {
                            root.titleClicks++;
                            if (root.titleClicks >= 7) {
                                root.titleClicks = 0;
                                root.easterEggOpen = true;
                            }
                        }
                    }
                }
                Repeater {
                    model: [{ label: "Keys", value: "keys" }, { label: "Capture", value: "capture" }]
                    Rectangle {
                        required property var modelData
                        implicitWidth: 76; implicitHeight: 30; radius: Theme.radiusPill
                        color: root.page === modelData.value ? Theme.primary : Theme.surfaceContainerHigh
                        StyledText { anchors.centerIn: parent; text: parent.modelData.label; font.pixelSize: 9; font.weight: Theme.fontWeightTitle }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.page = parent.modelData.value }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.page === "keys"
                spacing: Theme.space4
                Repeater {
                    model: root.bindings
                    Surface {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 42
                        color: Theme.surfaceContainer
                        RowLayout {
                            anchors { fill: parent; leftMargin: Theme.space12; rightMargin: Theme.space12 }
                            StyledText { text: parent.parent.modelData.keys; color: Theme.primary; font.family: Theme.fontFamilyNumeric; font.pixelSize: 10; font.weight: Theme.fontWeightLabel; Layout.preferredWidth: 180 }
                            StyledText { text: parent.parent.modelData.action; Layout.fillWidth: true }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.page === "capture"
                spacing: Theme.space12
                StyledText { text: "What to Capture"; color: Theme.primary; font.pixelSize: 10; font.weight: Theme.fontWeightTitle }
                RowLayout {
                    Layout.fillWidth: true; spacing: Theme.space8
                    Repeater {
                        model: [{ label: "Desktop", value: "desktop" }, { label: "Monitor", value: "monitor" }, { label: "Area", value: "area" }]
                        QuickToggleTile {
                            required property var modelData
                            Layout.fillWidth: true
                            title: modelData.label
                            subtitle: root.captureMode === modelData.value ? "Selected" : ""
                            checked: root.captureMode === modelData.value
                            onActivated: root.captureMode = modelData.value
                        }
                    }
                }
                StyledText { text: "Countdown"; color: Theme.primary; font.pixelSize: 10; font.weight: Theme.fontWeightTitle }
                RowLayout {
                    Layout.fillWidth: true; spacing: Theme.space8
                    Repeater {
                        model: [{ label: "Instant", value: 0 }, { label: "3 Seconds", value: 3 }, { label: "5 Seconds", value: 5 }]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; implicitHeight: 38; radius: Theme.radiusPill
                            color: root.captureDelay === modelData.value ? Theme.primary : Theme.surfaceContainerHigh
                            StyledText { anchors.centerIn: parent; text: parent.modelData.label; font.pixelSize: 9; font.weight: Theme.fontWeightTitle }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.captureDelay = parent.modelData.value }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 44; radius: Theme.radiusPill; color: capturePointer.containsMouse ? Theme.primary : Theme.primaryContainer
                    StyledText { anchors.centerIn: parent; text: "Take Screenshot"; font.weight: Theme.fontWeightTitle }
                    MouseArea { id: capturePointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.capture() }
                }
            }

            StyledText { Layout.fillWidth: true; visible: root.status.length > 0; text: root.status; color: Theme.foregroundSurfaceVariant; font.pixelSize: Theme.fontSmall; horizontalAlignment: Text.AlignHCenter }
        }
    }

    Surface {
        anchors.centerIn: parent
        visible: root.easterEggOpen
        width: 360; implicitHeight: 420; radius: Theme.radiusLarge
        color: Theme.surfaceContainerHigh
        z: 10
        Image {
            anchors { fill: parent; margins: Theme.space8 }
            source: Quickshell.shellDir + "/../../assets/images/alya-easter-egg.png"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        MouseArea { anchors.fill: parent; onClicked: root.easterEggOpen = false }
    }

    Item {
        anchors.fill: parent
        visible: root.selectionMode
        z: 30

        Rectangle {
            anchors.fill: parent
            visible: !root.selectionDragging
            color: "#99000000"
        }

        Rectangle {
            visible: root.selectionDragging
            x: 0; y: 0; width: parent.width
            height: Math.min(root.selectionStartY, root.selectionCurrentY)
            color: "#99000000"
        }
        Rectangle {
            visible: root.selectionDragging
            x: 0
            y: Math.max(root.selectionStartY, root.selectionCurrentY)
            width: parent.width
            height: parent.height - y
            color: "#99000000"
        }
        Rectangle {
            visible: root.selectionDragging
            x: 0
            y: Math.min(root.selectionStartY, root.selectionCurrentY)
            width: Math.min(root.selectionStartX, root.selectionCurrentX)
            height: Math.abs(root.selectionCurrentY - root.selectionStartY)
            color: "#99000000"
        }
        Rectangle {
            visible: root.selectionDragging
            x: Math.max(root.selectionStartX, root.selectionCurrentX)
            y: Math.min(root.selectionStartY, root.selectionCurrentY)
            width: parent.width - x
            height: Math.abs(root.selectionCurrentY - root.selectionStartY)
            color: "#99000000"
        }

        Rectangle {
            visible: root.selectionDragging
            x: Math.min(root.selectionStartX, root.selectionCurrentX)
            y: Math.min(root.selectionStartY, root.selectionCurrentY)
            width: Math.abs(root.selectionCurrentX - root.selectionStartX)
            height: Math.abs(root.selectionCurrentY - root.selectionStartY)
            color: "transparent"
            border.color: Theme.primary
            border.width: 4
        }

        StyledText {
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: Theme.space24 }
            text: root.selectionDragging
                ? Math.round(Math.abs(root.selectionCurrentX - root.selectionStartX))
                    + " × " + Math.round(Math.abs(root.selectionCurrentY - root.selectionStartY))
                : "Drag to select an area • Esc to cancel"
            color: Theme.foregroundPrimary
            font.weight: Theme.fontWeightLabel
        }

        MouseArea {
            id: selectionPointer
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.CrossCursor
            onPressed: mouse => {
                root.selectionDragging = true;
                root.selectionStartX = mouse.x;
                root.selectionStartY = mouse.y;
                root.selectionCurrentX = mouse.x;
                root.selectionCurrentY = mouse.y;
            }
            onPositionChanged: mouse => {
                root.selectionCurrentX = mouse.x;
                root.selectionCurrentY = mouse.y;
            }
            onReleased: mouse => {
                root.selectionCurrentX = mouse.x;
                root.selectionCurrentY = mouse.y;
                root.selectionDragging = false;
                root.finishSelection();
            }
        }
    }

    CapturePill {
        id: capturePill
        screen: root.screen
        onAreaScreenshotRequested: delay => {
            root.captureMode = "area";
            root.captureDelay = delay;
            root.capture();
        }
    }
}
