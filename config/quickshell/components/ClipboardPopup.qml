import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "../settings"
import "../theme"

PanelWindow {
    id: root
    required property var hostWindow
    property bool panelOpen: false
    property string query: ""
    readonly property var filteredEntries: ClipboardService.entries.filter(entry =>
        query.length === 0 || entry.preview.toLowerCase().includes(query.toLowerCase()))

    function openPanel() {
        closeTimer.stop(); visible = true; panelOpen = true;
        ClipboardService.refresh(); refreshTimer.start();
    }
    function closePanel() {
        panelOpen = false; refreshTimer.stop(); closeTimer.restart();
    }

    screen: hostWindow.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    visible: false
    WlrLayershell.namespace: "ayame-shell-clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible
        ? WlrLayershell.OnDemand : WlrLayershell.None

    Shortcut { sequence: "Escape"; onActivated: root.closePanel() }
    MouseArea { anchors.fill: parent; onClicked: root.closePanel() }
    Timer {
        id: closeTimer; interval: Theme.motionNormal + Theme.motionUnmapGrace
        onTriggered: root.visible = false
    }
    Timer {
        id: refreshTimer; interval: 1500; repeat: true
        onTriggered: ClipboardService.refresh()
    }

    Surface {
        anchors.centerIn: parent
        width: Math.min(560, root.width - Theme.space24 * 2)
        height: Math.min(650, root.height - Theme.space24 * 2)
        color: Theme.surface
        opacity: root.panelOpen ? 1 : 0
        scale: root.panelOpen ? 1 : 0.94
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
                    StyledText { text: "Clipboard History"; font.pixelSize: Theme.fontTitle; font.weight: Theme.fontWeightTitle }
                    StyledText {
                        text: ShellConfig.clipboardHistoryEnabled
                            ? "Text and image history stays on this device"
                            : "Disabled for privacy"
                        color: Theme.foregroundSurfaceVariant; font.pixelSize: Theme.fontSmall
                    }
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

            Surface {
                Layout.fillWidth: true; implicitHeight: 42
                color: Theme.surfaceContainer
                StyledText { anchors.left: parent.left; anchors.leftMargin: Theme.space12; anchors.verticalCenter: parent.verticalCenter; text: "⌕"; color: Theme.outline }
                TextInput {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                    anchors.leftMargin: 38; anchors.rightMargin: Theme.space12
                    color: Theme.foregroundSurface; selectionColor: Theme.primaryContainer
                    font.family: Theme.fontFamily; font.pixelSize: Theme.fontNormal
                    clip: true
                    onTextChanged: root.query = text
                    StyledText {
                        visible: parent.text.length === 0; text: "Search clipboard"
                        color: Theme.outline; font.pixelSize: Theme.fontNormal
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: !ShellConfig.clipboardHistoryEnabled || root.filteredEntries.length === 0
                text: !ShellConfig.clipboardHistoryEnabled
                    ? "Enable clipboard history in Ayame Settings → Services.\nPassword-manager entries are always ignored."
                    : "Your clipboard history is empty."
                color: Theme.foregroundSurfaceVariant; horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter; wrapMode: Text.WordWrap
            }

            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: ShellConfig.clipboardHistoryEnabled && root.filteredEntries.length > 0
                clip: true; spacing: Theme.space8; model: root.filteredEntries
                delegate: Surface {
                    required property var modelData
                    width: ListView.view.width
                    implicitHeight: modelData.kind === "image" ? 112 : 70
                    color: Theme.surfaceContainer
                    RowLayout {
                        anchors { fill: parent; margins: Theme.space10 }
                        spacing: Theme.space10
                        Image {
                            visible: parent.parent.modelData.kind === "image"
                            Layout.preferredWidth: visible ? 92 : 0; Layout.fillHeight: true
                            source: visible ? "file://" + parent.parent.modelData.path : ""
                            fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            StyledText {
                                Layout.fillWidth: true
                                text: parent.parent.parent.modelData.preview
                                maximumLineCount: 3; elide: Text.ElideRight; wrapMode: Text.Wrap
                            }
                            StyledText {
                                text: parent.parent.parent.modelData.kind.toUpperCase()
                                color: Theme.outline; font.pixelSize: 9; font.weight: Theme.fontWeightTitle
                            }
                        }
                        StyledText {
                            text: "COPY"; color: copyPointer.containsMouse ? Theme.primary : Theme.foregroundSurfaceVariant
                            font.pixelSize: 9; font.weight: Theme.fontWeightTitle
                            MouseArea {
                                id: copyPointer; anchors { fill: parent; margins: -Theme.space8 }
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: ClipboardService.run("copy", parent.parent.parent.modelData.id)
                            }
                        }
                        StyledText {
                            text: "×"; color: deletePointer.containsMouse ? Theme.error : Theme.outline
                            font.pixelSize: 18
                            MouseArea {
                                id: deletePointer; anchors { fill: parent; margins: -Theme.space8 }
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: ClipboardService.run("delete", parent.parent.parent.modelData.id)
                            }
                        }
                    }
                }
            }

            QuickActionButton {
                Layout.fillWidth: true; visible: ShellConfig.clipboardHistoryEnabled
                icon: "󰆴"; label: "Clear clipboard history"; danger: true
                onActivated: ClipboardService.run("clear")
            }
        }
    }
}
