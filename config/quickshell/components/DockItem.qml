import QtQuick
import Quickshell
import Quickshell.Widgets
import "../settings"
import "../theme"

Rectangle {
    id: root

    property var toplevel: null
    property string desktopId: ""
    readonly property string appId: desktopId.length > 0 ? desktopId
        : toplevel?.wayland?.appId || toplevel?.lastIpcObject?.class || ""
    readonly property var desktopEntry: desktopId.length > 0
        ? (DesktopEntries.byId(desktopId) || DesktopEntries.heuristicLookup(desktopId))
        : DesktopEntries.heuristicLookup(appId)
    readonly property string favoriteId: desktopEntry?.id || appId
    readonly property bool active: toplevel?.activated || false
    readonly property bool urgent: toplevel?.urgent || false
    readonly property bool pinned: ShellConfig.dockAppPinned(favoriteId)
    property bool pinChanging: false

    implicitWidth: 42
    implicitHeight: 42
    radius: Theme.radiusMedium
    color: active ? Theme.primaryContainer
        : pointer.containsMouse ? Theme.surfaceContainerHigh : "transparent"
    scale: pointer.pressed ? 0.9 : pointer.containsMouse ? 1.08 : 1
    y: pointer.containsMouse ? -Theme.space4 : 0
    opacity: 0

    transform: Translate { id: pinSlide; x: 14 }

    Component.onCompleted: enterAnimation.start()

    ParallelAnimation {
        id: enterAnimation
        NumberAnimation {
            target: root; property: "opacity"; to: 1
            duration: Theme.motionNormal; easing.type: Theme.easeEnter
        }
        NumberAnimation {
            target: pinSlide; property: "x"; to: 0
            duration: Theme.motionNormal; easing.type: Theme.easeEnter
        }
    }

    SequentialAnimation {
        id: pinAnimation
        ParallelAnimation {
            NumberAnimation {
                target: root; property: "opacity"; to: 0
                duration: Theme.motionFast; easing.type: Theme.easeExit
            }
            NumberAnimation {
                target: pinSlide; property: "x"; to: -16
                duration: Theme.motionFast; easing.type: Theme.easeExit
            }
        }
        ScriptAction {
            script: ShellConfig.toggleDockFavorite(root.favoriteId)
        }
    }

    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    Behavior on scale {
        NumberAnimation { duration: Theme.motionFast; easing.type: Theme.easeEnter }
    }
    Behavior on y {
        NumberAnimation { duration: Theme.motionFast; easing.type: Theme.easeEnter }
    }
    Behavior on x {
        enabled: !pinAnimation.running
        NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter }
    }

    readonly property string resolvedIcon: Quickshell.iconPath(
        root.desktopEntry?.icon || "", true)

    IconImage {
        id: appIcon
        anchors.centerIn: parent
        implicitSize: 28
        source: root.resolvedIcon
        visible: root.resolvedIcon.length > 0
        asynchronous: true
        mipmap: true
    }

    Rectangle {
        anchors.centerIn: parent
        width: 28
        height: 28
        visible: root.resolvedIcon.length === 0
        radius: Theme.radiusSmall
        color: Theme.primaryContainer
        StyledText {
            anchors.centerIn: parent
            text: (root.desktopEntry?.name || root.appId || "?").slice(0, 1).toUpperCase()
            color: Theme.foregroundPrimaryContainer
            font.weight: Theme.fontWeightTitle
        }
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
            NumberAnimation { duration: Theme.motionNormal; easing.type: Theme.easeEnter }
        }
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: event => {
            if (event.button === Qt.RightButton) {
                if (!root.pinChanging) {
                    root.pinChanging = true;
                    pinAnimation.start();
                }
                return;
            }

            if (!root.toplevel) {
                root.desktopEntry?.execute();
            } else if (!root.toplevel.wayland) {
                return;
            } else if (root.active) {
                root.toplevel.wayland.minimized = true;
            } else {
                root.toplevel.wayland.activate();
            }
        }
    }
}
