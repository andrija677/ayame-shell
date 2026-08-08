import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

PopupWindow {
    id: root

    required property var hostWindow
    property var executables: []
    property string query: ""
    property string status: ""
    signal appAdded(string name, string path)

    readonly property var filteredExecutables: {
        const needle = query.trim().toLowerCase();
        if (needle.length === 0)
            return executables;
        return executables.filter(path => {
            const name = path.substring(path.lastIndexOf("/") + 1);
            return (name + " " + path).toLowerCase().includes(needle);
        });
    }

    function open() {
        query = "";
        status = "";
        visible = true;
        scanner.running = true;
        focusRetry.start();
    }

    function close() {
        focusRetry.stop();
        visible = false;
    }

    function add(path) {
        if (registration.running)
            return;
        status = "Adding app…";
        registration.selectedPath = path;
        registration.command = [
            Quickshell.shellDir + "/../../scripts/ayame-add-app.sh",
            path
        ];
        registration.running = true;
    }

    anchor.window: hostWindow
    anchor.rect.x: Math.round((hostWindow.width - width) / 2)
    anchor.rect.y: Math.round((hostWindow.height - height) / 2)
    implicitWidth: Math.min(520, hostWindow.screen.width - Theme.space24 * 2)
    implicitHeight: Math.min(560, hostWindow.screen.height - Theme.space24 * 3)
    color: "transparent"
    grabFocus: true
    visible: false

    onVisibleChanged: {
        if (!visible)
            focusRetry.stop();
    }

    Timer {
        id: focusRetry
        interval: 8
        repeat: true
        onTriggered: {
            search.forceActiveFocus();
            if (search.activeFocus)
                stop();
        }
    }

    Surface {
        anchors.fill: parent
        color: Theme.surfaceContainerHigh

        ColumnLayout {
            anchors { fill: parent; margins: Theme.space12 }
            spacing: Theme.space12

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    StyledText {
                        text: "Add an app"
                        font.pixelSize: Theme.fontTitle
                        font.weight: Theme.fontWeightTitle
                    }
                    StyledText {
                        text: "Choose a runnable file to add to the application launcher"
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
                        onClicked: root.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: Theme.radiusMedium
                color: Theme.surfaceContainer
                border.color: search.activeFocus ? Theme.primary : Theme.outlineVariant
                border.width: 1

                StyledText {
                    anchors { left: parent.left; leftMargin: Theme.space12; verticalCenter: parent.verticalCenter }
                    text: "⌕"
                    color: Theme.primary
                    font.pixelSize: 18
                    font.weight: Theme.fontWeightTitle
                }

                TextInput {
                    id: search
                    anchors { fill: parent; leftMargin: 40; rightMargin: Theme.space12 }
                    color: Theme.foregroundSurface
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontNormal
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    clip: true
                    onTextChanged: root.query = text

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: parent.text.length === 0
                        text: "Search runnable files…"
                        color: Theme.outline
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: "Applications, Downloads, Desktop, and local commands"
                color: Theme.primary
                font.pixelSize: 10
                font.weight: Theme.fontWeightTitle
            }

            ListView {
                id: executableList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.filteredExecutables
                spacing: Theme.space4
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: executableDelegate
                    required property string modelData
                    width: ListView.view.width
                    height: 54
                    radius: Theme.radiusMedium
                    color: executablePointer.containsMouse
                        ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                    scale: executablePointer.pressed ? 0.985 : 1

                    readonly property string fileName: modelData.substring(
                        modelData.lastIndexOf("/") + 1)

                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                    Behavior on scale { NumberAnimation { duration: Theme.motionFast } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.space12; rightMargin: Theme.space12 }
                        spacing: Theme.space12

                        Rectangle {
                            implicitWidth: 30
                            implicitHeight: 30
                            radius: Theme.radiusSmall
                            color: Theme.primaryContainer
                            StyledText {
                                anchors.centerIn: parent
                                text: executableDelegate.fileName.slice(0, 1).toUpperCase()
                                color: Theme.foregroundPrimaryContainer
                                font.weight: Theme.fontWeightTitle
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                Layout.fillWidth: true
                                text: executableDelegate.fileName
                                font.weight: Theme.fontWeightLabel
                                elide: Text.ElideMiddle
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: executableDelegate.modelData
                                color: Theme.foregroundSurfaceVariant
                                font.pixelSize: Theme.fontSmall
                                elide: Text.ElideMiddle
                            }
                        }

                        StyledText {
                            text: "Add"
                            color: Theme.primary
                            font.pixelSize: 9
                            font.weight: Theme.fontWeightTitle
                        }
                    }

                    MouseArea {
                        id: executablePointer
                        anchors.fill: parent
                        enabled: !registration.running
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.add(executableDelegate.modelData)
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: parent.count === 0
                    text: scanner.running ? "Finding runnable files…"
                        : root.query.length > 0 ? "No matching files"
                        : "No runnable files found in common locations"
                    color: Theme.outline
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.status.length > 0 ? root.status
                    : "Only the launcher entry is created—the original file stays where it is."
                color: root.status.endsWith(" added") ? Theme.success : Theme.outline
                font.pixelSize: 9
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    Process {
        id: scanner
        command: [
            "sh", "-c",
            "find \"$HOME/Applications\" \"$HOME/Downloads\" \"$HOME/Desktop\" "
                + "\"${XDG_BIN_HOME:-$HOME/.local/bin}\" -maxdepth 4 -type f "
                + "\\( -perm /u=x,g=x,o=x -o -iname '*.appimage' \\) "
                + "-not -name '*.desktop' -print 2>/dev/null | sort -u"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const clean = text.trim();
                root.executables = clean.length > 0 ? clean.split("\n") : [];
            }
        }
    }

    Process {
        id: registration
        property string selectedPath: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim();
                if (name.length > 0) {
                    root.status = name + " added";
                    root.appAdded(name, registration.selectedPath);
                    closeTimer.restart();
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.status = "Could not add that file";
        }
    }

    Timer {
        id: closeTimer
        interval: 850
        onTriggered: root.close()
    }
}
