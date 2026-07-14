import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../settings"
import "../theme"

PopupWindow {
    id: root
    required property var hostWindow
    required property var wallpaperPicker

    function open() {
        pathInput.text = ShellConfig.dynamicColorWallpaper;
        visible = true;
        pathInput.forceActiveFocus();
    }

    function generatePalette() {
        DynamicPalette.useManual();
        ShellConfig.dynamicColorWallpaper = pathInput.text.trim();
        WallpaperService.apply(ShellConfig.dynamicColorWallpaper);
        DynamicPalette.generate(ShellConfig.dynamicColorWallpaper);
    }

    function chooseWallpaper() {
        visible = false;
        wallpaperPicker.open();
    }

    anchor.window: hostWindow
    anchor.rect.x: Math.round((hostWindow.width - width) / 2)
    anchor.rect.y: hostWindow.height + 72
    implicitWidth: 440
    implicitHeight: setupSurface.implicitHeight
    color: "transparent"
    grabFocus: true
    visible: false

    Surface {
        id: setupSurface
        width: parent.width
        implicitHeight: setupColumn.implicitHeight + Theme.space24
        color: Theme.surfaceContainerHigh

        ColumnLayout {
            id: setupColumn
            anchors { fill: parent; margins: Theme.space12 }
            spacing: Theme.space12

            StyledText {
                text: "Wallpaper colors"
                font.pixelSize: Theme.fontTitle
                font.weight: Theme.fontWeightLabel
            }

            StyledText {
                Layout.fillWidth: true
                text: "Generate a private local palette with Matugen. Ayame never uploads the image."
                color: Theme.foregroundSurfaceVariant
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8

                Repeater {
                    model: [
                        { label: "Follow Wallpaper", value: "automatic" },
                        { label: "Manual", value: "manual" }
                    ]

                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: Theme.radiusPill
                        color: ShellConfig.dynamicColorMode === modelData.value
                            ? Theme.primaryContainer : Theme.outlineVariant
                        StyledText {
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: ShellConfig.dynamicColorMode === parent.modelData.value
                                ? Theme.foregroundPrimaryContainer
                                : Theme.foregroundSurfaceVariant
                            font.pixelSize: 9
                            font.weight: Theme.fontWeightTitle
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (parent.modelData.value === "automatic")
                                    DynamicPalette.useAutomatic();
                                else
                                    DynamicPalette.useManual();
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: ShellConfig.dynamicColorMode === "automatic"
                text: DynamicPalette.detectedWallpaper.length > 0
                    ? "Watching " + DynamicPalette.detectedWallpaper
                    : "Waiting for your wallpaper service…"
                color: Theme.foregroundSurfaceVariant
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideMiddle
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                visible: ShellConfig.dynamicColorMode === "manual"
                radius: Theme.radiusSmall
                color: Theme.surfaceContainer
                border.color: pathInput.activeFocus ? Theme.primary : Theme.outlineVariant

                TextInput {
                    id: pathInput
                    anchors { fill: parent; margins: Theme.space12 }
                    color: Theme.foregroundSurface
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontNormal
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    clip: true
                    onAccepted: root.generatePalette()
                }

                StyledText {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    anchors.leftMargin: Theme.space12
                    visible: pathInput.text.length === 0 && !pathInput.activeFocus
                    text: "/home/you/Pictures/wallpaper.jpg"
                    color: Theme.outline
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignRight
                implicitWidth: 92
                implicitHeight: 30
                visible: ShellConfig.dynamicColorMode === "manual"
                radius: Theme.radiusPill
                color: browsePointer.containsMouse ? Theme.primary : Theme.primaryContainer
                StyledText {
                    anchors.centerIn: parent
                    text: "Browse…"
                    color: browsePointer.containsMouse
                        ? Theme.foregroundPrimary : Theme.foregroundPrimaryContainer
                    font.pixelSize: 9
                    font.weight: Theme.fontWeightTitle
                }
                MouseArea {
                    id: browsePointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.chooseWallpaper()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8

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
                            ? Theme.primary : stylePointer.containsMouse
                                ? Theme.surfaceContainer : Theme.outlineVariant

                        StyledText {
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: ShellConfig.dynamicColorStyle === parent.modelData.value
                                ? Theme.foregroundPrimary : Theme.foregroundSurfaceVariant
                            font.pixelSize: 9
                            font.weight: Theme.fontWeightTitle
                        }

                        MouseArea {
                            id: stylePointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellConfig.dynamicColorStyle = parent.modelData.value
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: DynamicPalette.generating || DynamicPalette.error.length > 0
                text: DynamicPalette.generating ? "Creating your palette…" : DynamicPalette.error
                color: DynamicPalette.error.length > 0 ? Theme.warning : Theme.outline
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space12

                StyledText {
                    Layout.fillWidth: true
                    visible: DynamicPalette.active
                    text: "Use Ayame Violet"
                    color: violetPointer.containsMouse ? Theme.primary : Theme.outline
                    font.pixelSize: 9
                    font.weight: Theme.fontWeightTitle
                    MouseArea {
                        id: violetPointer
                        anchors { fill: parent; margins: -Theme.space8 }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            DynamicPalette.disable();
                            root.visible = false;
                        }
                    }
                }

                StyledText {
                    text: "Cancel"
                    MouseArea {
                        anchors { fill: parent; margins: -Theme.space8 }
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.visible = false
                    }
                }

                Rectangle {
                    implicitWidth: 84
                    implicitHeight: 32
                    radius: Theme.radiusPill
                    color: generatePointer.containsMouse ? Theme.primary : Theme.primaryContainer
                    opacity: DynamicPalette.generating ? 0.55 : 1
                    visible: ShellConfig.dynamicColorMode === "manual"
                    StyledText {
                        anchors.centerIn: parent
                        text: "Apply"
                        color: generatePointer.containsMouse
                            ? Theme.foregroundPrimary : Theme.foregroundPrimaryContainer
                        font.pixelSize: 9
                        font.weight: Theme.fontWeightTitle
                    }
                    MouseArea {
                        id: generatePointer
                        anchors.fill: parent
                        enabled: !DynamicPalette.generating
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.generatePalette()
                    }
                }
            }
        }
    }

    Connections {
        target: DynamicPalette
        function onGeneratingChanged() {
            if (!DynamicPalette.generating && DynamicPalette.active
                    && DynamicPalette.error.length === 0)
                root.visible = false;
        }
    }
}
