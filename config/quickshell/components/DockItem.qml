import QtQuick
import Quickshell
import Quickshell.Widgets
import "../theme"

Rectangle {
    id: root

    required property var toplevel
    readonly property string appId: toplevel.wayland?.appId
        || toplevel.lastIpcObject?.class || ""
    readonly property var desktopEntry: DesktopEntries.heuristicLookup(appId)
    readonly property bool active: toplevel.activated
    readonly property bool urgent: toplevel.urgent

    implicitWidth: 42
    implicitHeight: 42
    radius: Theme.radiusMedium
    color: active ? Theme.primaryContainer
        : pointer.containsMouse ? Theme.surfaceContainerHigh : "transparent"
    scale: pointer.pressed ? 0.9 : pointer.containsMouse ? 1.08 : 1
    y: pointer.containsMouse ? -Theme.space4 : 0

    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    Behavior on scale {
        NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic }
    }

    IconImage {
        id: appIcon
        anchors.centerIn: parent
        implicitSize: 28
        source: Quickshell.iconPath(
            root.desktopEntry?.icon || "application-x-executable"
        )
        asynchronous: true
        mipmap: true
    }

    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 2
        }
        width: root.active ? 16 : 5
        height: 3
        radius: 2
        color: root.urgent ? Theme.error
            : root.active ? Theme.primary : Theme.outline

        Behavior on width {
            NumberAnimation { duration: Theme.motionNormal; easing.type: Easing.OutCubic }
        }
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (!root.toplevel.wayland)
                return;
            if (root.active)
                root.toplevel.wayland.minimized = true;
            else
                root.toplevel.wayland.activate();
        }
    }
}
