import QtQuick
import "../theme"

Rectangle {
    color: Theme.surfaceContainer
    radius: Theme.radiusMedium

    Behavior on color {
        ColorAnimation {
            duration: Theme.motionNormal
            easing.type: Theme.easeEnter
        }
    }
}
