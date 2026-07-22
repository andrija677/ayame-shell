import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root

    required property var hostWindow
    property bool panelOpen: false
    property var results: []
    property string statusText: "Checking Ayame…"

    function openPanel() {
        closeTimer.stop();
        visible = true;
        panelOpen = true;
        runCheck();
    }

    function closePanel() {
        panelOpen = false;
        closeTimer.restart();
    }

    function runCheck() {
        if (doctor.running) return;
        statusText = "Checking Ayame…";
        doctor.command = [
            Quickshell.shellDir + "/../../scripts/ayame-doctor.sh", "status"
        ];
        doctor.running = true;
    }

    function stateColor(state) {
        if (state === "healthy") return Theme.success;
        if (state === "error") return Theme.error;
        if (state === "warning") return Theme.warning;
        return Theme.outline;
    }

    screen: hostWindow.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    visible: false
    WlrLayershell.namespace: "ayame-shell-diagnostics"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible
        ? WlrLayershell.OnDemand : WlrLayershell.None

    Shortcut { sequence: "Escape"; onActivated: root.closePanel() }
    MouseArea { anchors.fill: parent; onClicked: root.closePanel() }

    Timer {
        id: closeTimer
        interval: Theme.motionNormal + Theme.motionUnmapGrace
        onTriggered: root.visible = false
    }

    Process {
        id: doctor
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                for (const line of text.trim().split("\n")) {
                    const fields = line.split("|");
                    if (fields.length >= 4) {
                        rows.push({
                            id: fields[0], label: fields[1], state: fields[2],
                            detail: fields.slice(3).join("|")
                        });
                    }
                }
                root.results = rows;
                const failures = rows.filter(row => row.state === "error").length;
                root.statusText = failures === 0
                    ? "Everything essential looks healthy"
                    : failures + " issue" + (failures === 1 ? "" : "s") + " need attention";
            }
        }
    }

    Process { id: actionProcess }

    Surface {
        anchors.centerIn: parent
        width: Math.min(560, root.width - Theme.space24 * 2)
        height: Math.min(650, root.height - Theme.space24 * 2)
        radius: Theme.radiusLarge
        color: Theme.surface
        opacity: root.panelOpen ? 1 : 0
        scale: root.panelOpen ? 1 : 0.94

        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }
        Behavior on scale {
            NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter }
        }
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors { fill: parent; margins: Theme.space16 }
            spacing: Theme.space12

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space2
                    StyledText {
                        text: "Ayame Diagnostics"
                        font.pixelSize: Theme.fontTitle
                        font.weight: Theme.fontWeightTitle
                    }
                    StyledText {
                        text: root.statusText
                        color: Theme.foregroundSurfaceVariant
                        font.pixelSize: Theme.fontSmall
                    }
                }
                StyledText {
                    text: "Close"
                    color: closePointer.containsMouse ? Theme.primary : Theme.outline
                    font.pixelSize: 9
                    font.weight: Theme.fontWeightTitle
                    MouseArea {
                        id: closePointer
                        anchors { fill: parent; margins: -Theme.space8 }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closePanel()
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.space6
                clip: true
                model: root.results
                delegate: Surface {
                    required property var modelData
                    width: ListView.view.width
                    implicitHeight: 58
                    color: Theme.surfaceContainer
                    radius: Theme.radiusMedium
                    RowLayout {
                        anchors { fill: parent; margins: Theme.space12 }
                        Rectangle {
                            implicitWidth: 9
                            implicitHeight: 9
                            radius: 5
                            color: root.stateColor(parent.parent.modelData.state)
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                text: parent.parent.parent.modelData.label
                                font.weight: Theme.fontWeightLabel
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: parent.parent.parent.modelData.detail
                                color: Theme.foregroundSurfaceVariant
                                font.pixelSize: Theme.fontSmall
                                elide: Text.ElideRight
                            }
                        }
                        StyledText {
                            text: parent.parent.modelData.state.toUpperCase()
                            color: root.stateColor(parent.parent.modelData.state)
                            font.pixelSize: 9
                            font.weight: Theme.fontWeightTitle
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8
                QuickActionButton {
                    Layout.fillWidth: true
                    icon: "↻"
                    label: "Run again"
                    primary: true
                    onActivated: root.runCheck()
                }
                QuickActionButton {
                    Layout.fillWidth: true
                    icon: "●"
                    label: "Test notification"
                    onActivated: {
                        actionProcess.command = [
                            Quickshell.shellDir + "/../../scripts/ayame-doctor.sh",
                            "test-notification"
                        ];
                        actionProcess.running = true;
                    }
                }
            }
        }
    }
}
