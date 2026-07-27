import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../settings"
import "../../theme"

PanelWindow {
    id: root
    required property var hostWindow
    property bool revealed: hover.hovered || pointer.containsMouse

    screen: hostWindow.screen
    anchors { left: true; bottom: true }
    implicitWidth: 64
    implicitHeight: 64
    exclusiveZone: 0
    visible: ShellConfig.aiEnabled
    color: "transparent"
    mask: Region { item: activationRegion }
    WlrLayershell.namespace: "ayame-shell-ai-corner"
    WlrLayershell.layer: WlrLayer.Top

    HoverHandler { id: hover }

    Item {
        id: activationRegion
        anchors.fill: parent
    }

    Rectangle {
        id: hotCorner
        anchors { left: parent.left; bottom: parent.bottom; margins: Theme.space8 }
        width: 44
        height: 44
        radius: Theme.radiusPill
        color: Theme.primaryContainer
        opacity: root.revealed ? 1 : 0
        scale: pointer.pressed ? 0.88 : root.revealed ? 1 : 0.68
        transformOrigin: Item.BottomLeft

        Behavior on opacity {
            NumberAnimation { duration: Theme.motionNormal }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.motionNormal
                easing.type: Theme.easeEnter
            }
        }

        Text {
            anchors.centerIn: parent
            text: "✦"
            color: Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: 19
            font.weight: Font.Bold
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chat.openPanel()
        }
    }

    AiChatPanel {
        id: chat
        hostWindow: root.hostWindow
    }
}
