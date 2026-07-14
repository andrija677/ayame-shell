import QtQuick
import QtQuick.Layouts
import "../theme"

Surface {
    id: root

    required property string title
    required property string subtitle
    property bool checked: false
    property bool interactive: true
    signal activated()

    implicitHeight: 64
    color: checked ? Theme.primaryContainer : Theme.surfaceContainer
    scale: pointer.pressed ? 0.98 : 1

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionFast
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        anchors { fill: parent; margins: Theme.space12 }
        spacing: Theme.space8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.space2

            StyledText {
                Layout.fillWidth: true
                text: root.title
                color: root.checked
                    ? Theme.foregroundPrimaryContainer
                    : Theme.foregroundSurface
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            StyledText {
                Layout.fillWidth: true
                text: root.subtitle
                color: root.checked
                    ? Theme.foregroundPrimaryContainer
                    : Theme.foregroundSurfaceVariant
                opacity: 0.82
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
            }
        }

        Rectangle {
            implicitWidth: 34
            implicitHeight: 20
            radius: Theme.radiusPill
            color: root.checked ? Theme.primary : Theme.outlineVariant

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: root.checked ? parent.width - width - 3 : 3
                width: 14
                height: 14
                radius: 7
                color: root.checked
                    ? Theme.foregroundPrimary
                    : Theme.foregroundSurfaceVariant

                Behavior on x {
                    NumberAnimation {
                        duration: Theme.motionNormal
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.activated()
    }
}
