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
    readonly property var bindings: [
        { keys: "SUPER", action: "Open launcher when released" },
        { keys: "SUPER + F", action: "Toggle fullscreen" },
        { keys: "SUPER + SHIFT + F", action: "Toggle floating / unlock window" },
        { keys: "SUPER + LEFT DRAG", action: "Move a floating window anywhere" },
        { keys: "SUPER + RIGHT DRAG", action: "Resize a floating window" },
        { keys: "SUPER + Q", action: "Close the active window" },
        { keys: "PRINT", action: "Capture the full desktop" },
        { keys: "SHIFT + PRINT", action: "Select an area to capture" },
        { keys: "SUPER + PRINT", action: "Capture the active monitor" }
    ]

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
        if (captureProcess.running)
            return;
        status = captureDelay > 0 ? "Capturing in " + captureDelay + " seconds…" : "Capturing…";
        panelOpen = false;
        visible = false;
        captureProcess.command = [
            Quickshell.shellDir + "/../../scripts/ayame-screenshot.sh",
            captureMode, captureDelay.toString(), screen.name
        ];
        captureProcess.running = true;
    }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    visible: false
    WlrLayershell.namespace: "ayame-shell-utilities"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: panelOpen ? WlrLayershell.OnDemand : WlrLayershell.None

    Shortcut { sequence: "Escape"; onActivated: root.closePanel() }
    Timer { id: closeTimer; interval: Theme.motionNormal; onTriggered: root.visible = false }

    Process {
        id: captureProcess
        stdout: StdioCollector {
            onStreamFinished: root.status = text.trim().length > 0
                ? "Saved to " + text.trim() : "Capture cancelled"
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    root.status = text.trim();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        opacity: root.panelOpen ? 0.72 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }
    }
    MouseArea { anchors.fill: parent; onClicked: root.closePanel() }

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
                    model: [{ label: "KEYS", value: "keys" }, { label: "CAPTURE", value: "capture" }]
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
                StyledText { text: "WHAT TO CAPTURE"; color: Theme.primary; font.pixelSize: 10; font.weight: Theme.fontWeightTitle }
                RowLayout {
                    Layout.fillWidth: true; spacing: Theme.space8
                    Repeater {
                        model: [{ label: "DESKTOP", value: "desktop" }, { label: "MONITOR", value: "monitor" }, { label: "AREA", value: "area" }]
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
                StyledText { text: "COUNTDOWN"; color: Theme.primary; font.pixelSize: 10; font.weight: Theme.fontWeightTitle }
                RowLayout {
                    Layout.fillWidth: true; spacing: Theme.space8
                    Repeater {
                        model: [{ label: "INSTANT", value: 0 }, { label: "3 SECONDS", value: 3 }, { label: "5 SECONDS", value: 5 }]
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
                    StyledText { anchors.centerIn: parent; text: "TAKE SCREENSHOT"; font.weight: Theme.fontWeightTitle }
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
}
