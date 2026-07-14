import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    required property int workspaceId
    required property bool active
    signal activated()

    implicitWidth: active ? 30 : 22
    implicitHeight: Theme.itemHeight
    radius: Theme.itemRadius
    color: active ? Theme.accent : "transparent"

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.animationFast }
    }

    Text {
        anchors.centerIn: parent
        text: root.workspaceId
        color: root.active ? Theme.surface : Theme.textMuted
        font.family: "Noto Sans"
        font.pixelSize: Theme.fontSmall
        font.weight: root.active ? Font.DemiBold : Font.Medium
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}

