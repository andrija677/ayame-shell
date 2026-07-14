import QtQuick
import Quickshell.Hyprland
import "../theme"

Item {
    id: root

    readonly property string windowTitle: Hyprland.activeToplevel?.title ?? ""

    visible: windowTitle.length > 0
    clip: true

    StyledText {
        id: titleLabel
        anchors.fill: parent
        text: root.windowTitle
        color: Theme.foregroundSurfaceVariant
        font.pixelSize: Theme.fontSmall
        font.weight: Theme.fontWeightBody
        elide: Text.ElideRight
        maximumLineCount: 1
        verticalAlignment: Text.AlignVCenter
    }
}
