import QtQuick
import Quickshell.Hyprland
import "../theme"

StyledText {
    id: root

    readonly property string windowTitle: Hyprland.activeToplevel?.title ?? ""

    text: windowTitle
    visible: windowTitle.length > 0
    color: Theme.foregroundSurfaceVariant
    font.pixelSize: Theme.fontSmall
    font.weight: Font.Medium
    elide: Text.ElideRight
    maximumLineCount: 1
    verticalAlignment: Text.AlignVCenter
}
