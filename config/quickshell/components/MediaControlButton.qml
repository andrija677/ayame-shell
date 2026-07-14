import QtQuick
import "../theme"

Rectangle {
    id: root

    property string label: ""
    property bool available: true
    signal activated()

    implicitWidth: label.length > 1 ? 42 : 32
    implicitHeight: 26
    radius: Theme.radiusPill
    visible: available
    color: pointer.containsMouse ? Theme.primary : Theme.primaryContainer

    StyledText {
        anchors.centerIn: parent
        text: root.label
        color: pointer.containsMouse
            ? Theme.foregroundPrimary : Theme.foregroundPrimaryContainer
        font.pixelSize: root.label.length > 1 ? 9 : 14
        font.weight: Theme.fontWeightTitle
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
