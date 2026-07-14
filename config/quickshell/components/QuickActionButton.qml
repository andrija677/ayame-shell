import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool primary: false
    property bool danger: false
    signal activated()

    implicitHeight: 44
    radius: Theme.radiusMedium
    color: pointer.containsMouse
        ? (danger ? Theme.error : Theme.primary)
        : primary ? Theme.primaryContainer : Theme.surfaceContainerHigh
    scale: pointer.pressed ? 0.97 : 1

    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    Behavior on scale {
        NumberAnimation { duration: Theme.motionFast; easing.type: Theme.easeEnter }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: Theme.space8

        StyledText {
            text: root.icon
            color: pointer.containsMouse
                ? Theme.foregroundPrimary
                : root.primary ? Theme.foregroundPrimaryContainer
                : root.danger ? Theme.error : Theme.primary
            font.family: Theme.fontFamilyNumeric
            font.pixelSize: 16
            font.weight: Theme.fontWeightLabel
        }

        StyledText {
            text: root.label
            color: pointer.containsMouse
                ? Theme.foregroundPrimary
                : root.primary ? Theme.foregroundPrimaryContainer
                : Theme.foregroundSurface
            font.pixelSize: 10
            font.weight: Theme.fontWeightTitle
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
