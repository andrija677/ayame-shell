import QtQuick
import "../theme"

Rectangle {
    id: root

    property string label: ""
    property bool available: true
    signal activated()

    implicitWidth: 32
    implicitHeight: 26
    radius: Theme.radiusPill
    visible: available
    color: pointer.containsMouse ? Theme.primary : Theme.primaryContainer

    StyledText {
        anchors.centerIn: parent
        text: root.label
        color: pointer.containsMouse
            ? Theme.foregroundPrimary : Theme.foregroundPrimaryContainer
        font.family: Theme.fontFamilyNumeric
        font.pixelSize: 14
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
