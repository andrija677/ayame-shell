import QtQuick
import "../services"
import "../theme"

Surface {
    id: root

    visible: MicrophoneService.active
    implicitWidth: visible ? label.implicitWidth + Theme.space16 : 0
    implicitHeight: Theme.itemHeight
    radius: Theme.radiusPill
    color: "#D97745"
    opacity: visible ? 1 : 0
    scale: visible ? 1 : 0.9

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter }
    }
    Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
    Behavior on scale {
        NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter }
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        text: "●  " + MicrophoneService.appName
            + (MicrophoneService.extraAppCount > 0
                ? "  +" + MicrophoneService.extraAppCount : "")
        color: "#FFF8F3"
        font.pixelSize: 10
        font.weight: Theme.fontWeightTitle
        elide: Text.ElideRight
    }
}
