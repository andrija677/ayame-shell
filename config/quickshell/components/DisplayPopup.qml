import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../theme"

PanelWindow {
    id: root
    required property var hostWindow
    property bool panelOpen: false
    property var selectedDisplay: null
    property var modes: []
    property string selectedMode: ""
    property real selectedScale: 1

    function openPanel() {
        closeTimer.stop(); visible = true; panelOpen = true;
        SystemControlService.refreshDisplays();
    }
    function closePanel() { panelOpen = false; closeTimer.restart(); }
    function selectDisplay(display) {
        selectedDisplay = display;
        selectedMode = display.width + "x" + display.height + "@" + display.rate;
        selectedScale = display.scale;
        modeProcess.command = [SystemControlService.script, "display-modes", display.name];
        modeProcess.running = true;
    }

    screen: hostWindow.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0; color: "transparent"; visible: false
    WlrLayershell.namespace: "ayame-shell-displays"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrLayershell.OnDemand : WlrLayershell.None
    Shortcut { sequence: "Escape"; onActivated: root.closePanel() }
    MouseArea { anchors.fill: parent; onClicked: root.closePanel() }
    Timer { id: closeTimer; interval: Theme.motionNormal + Theme.motionUnmapGrace; onTriggered: root.visible = false }
    Process {
        id: modeProcess
        stdout: StdioCollector {
            onStreamFinished: {
                root.modes = text.trim().length ? text.trim().split("\n") : [];
                if (root.selectedDisplay) {
                    const prefix = root.selectedDisplay.width + "x"
                        + root.selectedDisplay.height + "@";
                    const matching = root.modes.find(mode =>
                        mode.startsWith(prefix)
                        && Math.abs(Number(mode.split("@")[1].replace("Hz", ""))
                            - root.selectedDisplay.rate) < 1);
                    if (matching) root.selectedMode = matching;
                }
            }
        }
    }
    Process {
        id: applyProcess
        onRunningChanged: if (!running) SystemControlService.refreshDisplays()
    }

    Surface {
        anchors.centerIn: parent
        width: Math.min(600, root.width - Theme.space24 * 2)
        height: Math.min(620, root.height - Theme.space24 * 2)
        color: Theme.surface
        opacity: root.panelOpen ? 1 : 0; scale: root.panelOpen ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }
        Behavior on scale { NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter } }
        MouseArea { anchors.fill: parent }
        ColumnLayout {
            anchors { fill: parent; margins: Theme.space16 }
            spacing: Theme.space12
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true; spacing: Theme.space2
                    StyledText { text: "Display Controls"; font.pixelSize: Theme.fontTitle; font.weight: Theme.fontWeightTitle }
                    StyledText { text: "Resolution, refresh rate and scaling"; color: Theme.foregroundSurfaceVariant; font.pixelSize: Theme.fontSmall }
                }
                StyledText {
                    text: "Close"; color: closePointer.containsMouse ? Theme.primary : Theme.outline
                    font.pixelSize: 9; font.weight: Theme.fontWeightTitle
                    MouseArea {
                        id: closePointer; anchors { fill: parent; margins: -Theme.space8 }
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.closePanel()
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: Theme.space8
                Repeater {
                    model: SystemControlService.displays
                    QuickActionButton {
                        required property var modelData
                        Layout.fillWidth: true
                        icon: "󰍹"; label: modelData.name
                        primary: root.selectedDisplay?.name === modelData.name
                        onActivated: root.selectDisplay(modelData)
                    }
                }
            }
            StyledText {
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: root.selectedDisplay === null
                text: "Choose a display to adjust it. Ayame preserves its current desktop position."
                color: Theme.foregroundSurfaceVariant; horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter; wrapMode: Text.WordWrap
            }
            ColumnLayout {
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: root.selectedDisplay !== null; spacing: Theme.space12
                StyledText { text: root.selectedDisplay?.description ?? ""; elide: Text.ElideRight; Layout.fillWidth: true }
                StyledText { text: "Display mode"; color: Theme.primary; font.pixelSize: 10; font.weight: Theme.fontWeightTitle }
                ListView {
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                    spacing: Theme.space6; model: root.modes
                    delegate: Surface {
                        required property string modelData
                        width: ListView.view.width; implicitHeight: 42
                        color: root.selectedMode === modelData
                            ? Theme.primaryContainer : Theme.surfaceContainer
                        RowLayout {
                            anchors { fill: parent; margins: Theme.space12 }
                            StyledText { text: parent.parent.modelData; Layout.fillWidth: true }
                            StyledText { text: root.selectedMode === parent.parent.modelData ? "SELECTED" : "CHOOSE"; color: Theme.primary; font.pixelSize: 9; font.weight: Theme.fontWeightTitle }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedMode = parent.modelData
                        }
                    }
                }
                StyledText { text: "Scale"; color: Theme.primary; font.pixelSize: 10; font.weight: Theme.fontWeightTitle }
                RowLayout {
                    Layout.fillWidth: true; spacing: Theme.space6
                    Repeater {
                        model: [1, 1.25, 1.5, 1.75, 2]
                        Rectangle {
                            required property real modelData
                            Layout.fillWidth: true; implicitHeight: 32; radius: Theme.radiusPill
                            color: Math.abs(root.selectedScale - modelData) < 0.01
                                ? Theme.primary : Theme.surfaceContainer
                            StyledText { anchors.centerIn: parent; text: parent.modelData + "×"; font.pixelSize: Theme.fontSmall }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedScale = parent.modelData }
                        }
                    }
                }
                QuickActionButton {
                    Layout.fillWidth: true; icon: "✓"; label: "Apply display settings"; primary: true
                    onActivated: {
                        applyProcess.command = [SystemControlService.script, "display-apply",
                            root.selectedDisplay.name, root.selectedMode, String(root.selectedScale)];
                        applyProcess.running = true;
                    }
                }
            }
        }
    }
}
