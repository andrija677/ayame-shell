import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"
import "../settings"
import "../theme"

PopupWindow {
    id: root

    required property var hostWindow
    property var wallpapers: []

    function open() {
        visible = true;
        scanner.running = true;
    }

    function choose(path) {
        ShellConfig.dynamicColorMode = "manual";
        ShellConfig.dynamicColorWallpaper = path;
        WallpaperService.apply(path);
        DynamicPalette.generate(path);
        visible = false;
    }

    anchor.window: hostWindow
    anchor.rect.x: Math.round((hostWindow.width - width) / 2)
    anchor.rect.y: hostWindow.height + 72
    implicitWidth: 440
    implicitHeight: 480
    color: "transparent"
    grabFocus: true
    visible: false

    Surface {
        anchors.fill: parent
        color: Theme.surfaceContainerHigh

        ColumnLayout {
            anchors { fill: parent; margins: Theme.space12 }
            spacing: Theme.space12

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    text: "Choose wallpaper"
                    font.pixelSize: Theme.fontTitle
                    font.weight: Theme.fontWeightTitle
                }
                StyledText {
                    text: "CLOSE"
                    color: closePointer.containsMouse ? Theme.primary : Theme.outline
                    font.pixelSize: 9
                    font.weight: Theme.fontWeightTitle
                    MouseArea {
                        id: closePointer
                        anchors { fill: parent; margins: -Theme.space8 }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.visible = false
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: "Images in Pictures and Downloads"
                color: Theme.foregroundSurfaceVariant
                font.pixelSize: Theme.fontSmall
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Theme.space8
                model: root.wallpapers

                delegate: Rectangle {
                    required property string modelData
                    width: ListView.view.width
                    height: 54
                    radius: Theme.radiusSmall
                    color: imagePointer.containsMouse
                        ? Theme.primaryContainer : Theme.surfaceContainer

                    RowLayout {
                        anchors { fill: parent; margins: Theme.space8 }
                        spacing: Theme.space12
                        Image {
                            source: "file://" + modelData
                            sourceSize.width: 64
                            sourceSize.height: 42
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 42
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.substring(modelData.lastIndexOf("/") + 1)
                            elide: Text.ElideMiddle
                        }
                    }

                    MouseArea {
                        id: imagePointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.choose(parent.modelData)
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: parent.count === 0
                    text: scanner.running ? "Finding wallpapers…"
                        : "No PNG, JPEG, or WebP images found"
                    color: Theme.outline
                }
            }
        }
    }

    Process {
        id: scanner
        command: [
            "sh", "-c",
            "find \"$HOME/Pictures\" \"$HOME/Downloads\" -maxdepth 3 -type f "
                + "\\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) "
                + "-print 2>/dev/null | sort"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const clean = text.trim();
                root.wallpapers = clean.length > 0 ? clean.split("\n") : [];
            }
        }
    }
}
