import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../theme"

Item {
    id: root

    readonly property string windowTitle: Hyprland.activeToplevel?.title ?? ""
    readonly property string appId: Hyprland.activeToplevel?.wayland?.appId
        || Hyprland.activeToplevel?.lastIpcObject?.class || ""
    readonly property var desktopEntry: DesktopEntries.heuristicLookup(appId)
    readonly property string resolvedIcon: Quickshell.iconPath(
        desktopEntry?.icon || "", true)

    visible: windowTitle.length > 0
    clip: true

    RowLayout {
        anchors.fill: parent
        spacing: Theme.space6

        IconImage {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            source: root.resolvedIcon
            visible: root.resolvedIcon.length > 0
            asynchronous: true
            mipmap: true
            opacity: 0.86
        }

        StyledText {
            id: titleLabel
            Layout.fillWidth: true
            text: root.windowTitle
            color: Theme.foregroundSurfaceVariant
            font.pixelSize: Theme.fontSmall
            font.weight: Theme.fontWeightBody
            elide: Text.ElideRight
            maximumLineCount: 1
            verticalAlignment: Text.AlignVCenter
        }
    }
}
