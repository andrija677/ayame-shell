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
        ShellConfig.dynamicColorMode = "automatic";
        ShellConfig.dynamicColorWallpaper = path;
        WallpaperService.apply(path);
        DynamicPalette.followWallpaper(path);
    }

    anchor.window: hostWindow
    anchor.rect.x: Math.round((hostWindow.width - width) / 2)
    anchor.rect.y: hostWindow.height + Theme.space24
    implicitWidth: Math.min(540, hostWindow.screen.width - Theme.space24 * 2)
    implicitHeight: Math.min(590,
        hostWindow.screen.height - hostWindow.height - Theme.space24 * 3)
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

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    StyledText {
                        text: "Wallpaper & colors"
                        font.pixelSize: Theme.fontTitle
                        font.weight: Theme.fontWeightTitle
                    }
                    StyledText {
                        text: "Choose an image and Ayame creates its UI palette"
                        color: Theme.foregroundSurfaceVariant
                        font.pixelSize: Theme.fontSmall
                    }
                }

                StyledText {
                    text: "Close"
                    color: closePointer.containsMouse
                        ? Theme.primary : Theme.outline
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

            Surface {
                Layout.fillWidth: true
                implicitHeight: 66
                color: Theme.surfaceContainer

                RowLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    spacing: Theme.space8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        StyledText {
                            text: DynamicPalette.generating
                                ? "Creating wallpaper palette…"
                                : DynamicPalette.active
                                    ? "Wallpaper colors active"
                                    : "Ayame Violet active"
                            font.weight: Theme.fontWeightLabel
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: DynamicPalette.error.length > 0
                                ? DynamicPalette.error
                                : DynamicPalette.active
                                    ? ShellConfig.dynamicColorStyle
                                        + " • updates with every selection"
                                    : "Select any wallpaper to enable automatic colors"
                            color: DynamicPalette.error.length > 0
                                ? Theme.warning : Theme.foregroundSurfaceVariant
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        implicitWidth: 92
                        implicitHeight: 28
                        radius: Theme.radiusPill
                        color: violetPointer.containsMouse
                            ? Theme.primary : Theme.outlineVariant
                        visible: DynamicPalette.active
                        StyledText {
                            anchors.centerIn: parent
                            text: "AYAME VIOLET"
                            color: violetPointer.containsMouse
                                ? Theme.foregroundPrimary
                                : Theme.foregroundSurfaceVariant
                            font.pixelSize: 8
                            font.weight: Theme.fontWeightTitle
                        }
                        MouseArea {
                            id: violetPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: DynamicPalette.disable()
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space6

                StyledText {
                    text: "Palette style"
                    color: Theme.foregroundSurfaceVariant
                    font.pixelSize: Theme.fontSmall
                    font.weight: Theme.fontWeightLabel
                }

                Repeater {
                    model: [
                        { label: "Tonal", value: "tonal" },
                        { label: "Vibrant", value: "vibrant" },
                        { label: "Expressive", value: "expressive" }
                    ]

                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: Theme.radiusPill
                        color: ShellConfig.dynamicColorStyle === modelData.value
                            ? Theme.primary
                            : stylePointer.containsMouse
                                ? Theme.surfaceContainer
                                : Theme.outlineVariant
                        scale: stylePointer.pressed ? 0.96 : 1

                        Behavior on color {
                            ColorAnimation { duration: Theme.motionFast }
                        }
                        Behavior on scale {
                            NumberAnimation { duration: Theme.motionFast }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: ShellConfig.dynamicColorStyle
                                    === parent.modelData.value
                                ? Theme.foregroundPrimary
                                : Theme.foregroundSurfaceVariant
                            font.pixelSize: 9
                            font.weight: Theme.fontWeightTitle
                        }

                        MouseArea {
                            id: stylePointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ShellConfig.dynamicColorStyle
                                    = parent.modelData.value;
                                if (ShellConfig.dynamicColorWallpaper.length > 0) {
                                    ShellConfig.dynamicColorMode = "automatic";
                                    DynamicPalette.followWallpaper(
                                        ShellConfig.dynamicColorWallpaper);
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: "Pictures and Downloads"
                color: Theme.primary
                font.pixelSize: 10
                font.weight: Theme.fontWeightTitle
            }

            GridView {
                id: wallpaperGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: width / 2
                cellHeight: 126
                model: root.wallpapers
                boundsBehavior: Flickable.StopAtBounds

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Theme.motionNormal
                        }
                        NumberAnimation {
                            property: "scale"
                            from: 0.94
                            to: 1
                            duration: Theme.motionNormal
                            easing.type: Theme.easeEnter
                        }
                    }
                }

                delegate: Item {
                    id: wallpaperDelegate
                    required property string modelData
                    width: wallpaperGrid.cellWidth
                    height: wallpaperGrid.cellHeight
                    readonly property bool selected:
                        ShellConfig.dynamicColorWallpaper === modelData

                    Surface {
                        anchors {
                            fill: parent
                            rightMargin: Theme.space6
                            bottomMargin: Theme.space8
                        }
                        radius: Theme.radiusMedium
                        color: wallpaperDelegate.selected
                            ? Theme.primaryContainer : Theme.surfaceContainer
                        border.width: wallpaperDelegate.selected ? 2 : 0
                        border.color: Theme.primary
                        scale: imagePointer.pressed ? 0.97
                            : imagePointer.containsMouse ? 1.015 : 1
                        clip: true

                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.motionFast
                                easing.type: Theme.easeEnter
                            }
                        }
                        Behavior on color {
                            ColorAnimation { duration: Theme.motionNormal }
                        }

                        Image {
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                            }
                            height: parent.height - 30
                            source: "file://" + wallpaperDelegate.modelData
                            sourceSize.width: 260
                            sourceSize.height: 180
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }

                        Rectangle {
                            anchors {
                                right: parent.right
                                top: parent.top
                                margins: Theme.space8
                            }
                            width: 22
                            height: 22
                            radius: 11
                            visible: wallpaperDelegate.selected
                            color: Theme.primary
                            StyledText {
                                anchors.centerIn: parent
                                text: "✓"
                                color: Theme.foregroundPrimary
                                font.weight: Theme.fontWeightTitle
                            }
                        }

                        StyledText {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                leftMargin: Theme.space8
                                rightMargin: Theme.space8
                            }
                            height: 30
                            text: wallpaperDelegate.modelData.substring(
                                wallpaperDelegate.modelData.lastIndexOf("/") + 1)
                            color: wallpaperDelegate.selected
                                ? Theme.foregroundPrimaryContainer
                                : Theme.foregroundSurfaceVariant
                            font.pixelSize: 10
                            elide: Text.ElideMiddle
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: imagePointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.choose(wallpaperDelegate.modelData)
                        }
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

            StyledText {
                Layout.fillWidth: true
                text: "Palettes are generated locally with Matugen—images never leave this computer."
                color: Theme.outline
                font.pixelSize: 9
                horizontalAlignment: Text.AlignHCenter
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
