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
    property var pendingAction: null
    property string error: ""
    property string executingAction: ""
    readonly property var actions: [
        { id: "lock", glyph: "●", label: "Lock", detail: "Secure this session" },
        { id: "logout", glyph: "↪", label: "Log Out", detail: "End this Hyprland session" },
        { id: "restart", glyph: "↻", label: "Restart", detail: "Restart the computer" },
        { id: "shutdown", glyph: "⏻", label: "Shut Down", detail: "Power off the computer" }
    ]

    function openPanel() {
        closeTimer.stop();
        pendingAction = null;
        error = "";
        visible = true;
        panelOpen = true;
    }

    function closePanel() {
        panelOpen = false;
        pendingAction = null;
        closeTimer.restart();
    }

    function requestAction(action) {
        error = "";
        if (action.id === "lock") {
            executeAction(action);
            return;
        }
        pendingAction = action;
    }

    function executeAction(action) {
        if (!action || actionProcess.running)
            return;

        if (action.id === "lock") {
            actionProcess.command = [
                "hyprlock", "--config",
                Quickshell.shellDir + "/../hyprlock/hyprlock.conf",
                "--grace", "0", "--immediate-render"
            ];
        } else if (action.id === "logout") {
            actionProcess.command = [
                "hyprshutdown", "--no-fork", "--top-label",
                "Logging out of Ayame…"
            ];
        } else if (action.id === "restart") {
            actionProcess.command = ["systemctl", "reboot"];
        } else if (action.id === "shutdown") {
            actionProcess.command = ["systemctl", "poweroff"];
        } else {
            return;
        }

        panelOpen = false;
        pendingAction = null;
        visible = false;
        executingAction = action.id;
        actionProcess.running = true;
    }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    visible: false
    WlrLayershell.namespace: "ayame-shell-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: panelOpen
        ? WlrLayershell.OnDemand : WlrLayershell.None

    Shortcut {
        sequence: "Escape"
        onActivated: root.closePanel()
    }

    onVisibleChanged: {
        if (!visible && !actionProcess.running) {
            closeTimer.stop();
            panelOpen = false;
            pendingAction = null;
        }
    }

    Timer {
        id: closeTimer
        interval: Theme.motionNormal
        onTriggered: root.visible = false
    }

    Process {
        id: actionProcess
        stderr: StdioCollector {
            onStreamFinished: root.error = text.trim()
        }
        onExited: (exitCode, exitStatus) => {
            if (root.executingAction.length === 0)
                return;
            Qt.callLater(() => {
                const failed = exitCode !== 0;
                const failure = root.error.length > 0
                    ? root.error : "The system action could not be completed.";
                root.executingAction = "";
                if (failed) {
                    root.openPanel();
                    root.error = failure;
                } else {
                    root.error = "";
                }
            });
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        opacity: root.panelOpen ? 0.78 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closePanel()
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(760, root.width - Theme.space24 * 2)
        spacing: Theme.space24
        opacity: root.panelOpen ? 1 : 0
        scale: root.panelOpen ? 1 : 0.92

        Behavior on opacity { NumberAnimation { duration: Theme.motionNormal } }
        Behavior on scale {
            NumberAnimation {
                duration: root.panelOpen ? Theme.motionSlow : Theme.motionNormal
                easing.type: root.panelOpen ? Theme.easeEnter : Theme.easeExit
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.space4
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.pendingAction ? "Are you sure?" : "Power"
                font.pixelSize: 30
                font.weight: Theme.fontWeightDisplay
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.pendingAction
                    ? root.pendingAction.detail + ". Unsaved work may be lost."
                    : "Choose what Ayame should do"
                color: Theme.foregroundSurfaceVariant
                font.pixelSize: Theme.fontNormal
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space12
            visible: root.pendingAction === null

            Repeater {
                model: root.actions

                Surface {
                    id: actionTile
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 150
                    radius: Theme.radiusLarge
                    color: actionPointer.containsMouse
                        ? (modelData.id === "shutdown"
                            ? Theme.error : Theme.primary)
                        : Theme.surface
                    scale: actionPointer.pressed ? 0.95
                        : actionPointer.containsMouse ? 1.03 : 1

                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                    Behavior on scale {
                        NumberAnimation { duration: Theme.motionFast; easing.type: Theme.easeEnter }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - Theme.space24
                        spacing: Theme.space8
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: actionTile.modelData.glyph
                            color: actionPointer.containsMouse
                                ? Theme.foregroundPrimary : Theme.primary
                            font.pixelSize: 34
                            font.weight: Theme.fontWeightTitle
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: actionTile.modelData.label
                            color: actionPointer.containsMouse
                                ? Theme.foregroundPrimary : Theme.foregroundSurface
                            font.pixelSize: Theme.fontTitle
                            font.weight: Theme.fontWeightTitle
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: actionTile.modelData.detail
                            color: actionPointer.containsMouse
                                ? Theme.foregroundPrimary : Theme.foregroundSurfaceVariant
                            font.pixelSize: Theme.fontSmall
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
                    }

                    MouseArea {
                        id: actionPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.requestAction(actionTile.modelData)
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.space12
            visible: root.pendingAction !== null

            Rectangle {
                implicitWidth: 150
                implicitHeight: 44
                radius: Theme.radiusPill
                color: cancelPointer.containsMouse
                    ? Theme.surfaceContainerHigh : Theme.surface
                StyledText {
                    anchors.centerIn: parent
                    text: "CANCEL"
                    font.weight: Theme.fontWeightTitle
                }
                MouseArea {
                    id: cancelPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pendingAction = null
                }
            }

            Rectangle {
                implicitWidth: 190
                implicitHeight: 44
                radius: Theme.radiusPill
                color: confirmPointer.containsMouse
                    ? Theme.error : Theme.primaryContainer
                StyledText {
                    anchors.centerIn: parent
                    text: "CONFIRM " + (root.pendingAction?.label || "").toUpperCase()
                    color: confirmPointer.containsMouse
                        ? Theme.foregroundPrimary : Theme.foregroundPrimaryContainer
                    font.weight: Theme.fontWeightTitle
                }
                MouseArea {
                    id: confirmPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.executeAction(root.pendingAction)
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.error.length > 0
            text: root.error
            color: Theme.error
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
