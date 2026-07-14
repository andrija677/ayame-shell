import QtQuick
import "../theme"

QtObject {
    id: root

    property bool open: false
    property real value: 0
    property bool opening: false

    onOpenChanged: {
        animation.stop();
        opening = open;
        animation.from = value;
        animation.to = open ? 1 : 0;
        animation.restart();
    }

    property NumberAnimation animation: NumberAnimation {
        target: root
        property: "value"
        duration: Theme.motionNormal
        easing.type: root.opening ? Theme.easeEnter : Theme.easeExit
    }
}
