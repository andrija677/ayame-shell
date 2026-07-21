import QtQuick
import Quickshell
import "../services"
import "../theme"

Item {
    id: root

    required property var hostWindow
    visible: MicrophoneService.active
    implicitWidth: visible ? 18 : 0
    implicitHeight: Theme.itemHeight
    opacity: visible ? 1 : 0
    scale: visible ? 1 : 0.8

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter }
    }
    Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
    Behavior on scale {
        NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 9
        height: 9
        radius: width / 2
        color: "#E98249"
        border.width: 2
        border.color: "#5E2F1E"
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
    }

    PopupWindow {
        anchor.window: root.hostWindow
        anchor.rect.x: root.mapToItem(null, 0, 0).x
            - width / 2 + root.width / 2
        anchor.rect.y: root.hostWindow.height
        implicitWidth: tooltipLabel.implicitWidth + Theme.space24
        implicitHeight: 42
        color: "transparent"
        grabFocus: false
        visible: root.visible && pointer.containsMouse

        Surface {
            anchors { fill: parent; topMargin: Theme.space8 }
            radius: Theme.radiusMedium
            color: Theme.surfaceContainerHigh

            StyledText {
                id: tooltipLabel
                anchors.centerIn: parent
                text: MicrophoneService.appName + " is using your microphone!"
                    + (MicrophoneService.extraAppCount > 0
                        ? "  +" + MicrophoneService.extraAppCount + " more" : "")
                font.pixelSize: Theme.fontSmall
                font.weight: Theme.fontWeightLabel
            }
        }
    }
}
