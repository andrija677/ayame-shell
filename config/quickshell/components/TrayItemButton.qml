import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../settings"
import "../theme"

Rectangle {
    id: root

    required property var trayItem
    required property var hostWindow

    readonly property bool itemVisible: ShellConfig.showPassiveTrayItems
        || trayItem.status !== Status.Passive

    visible: itemVisible
    implicitWidth: itemVisible ? Theme.itemHeight : 0
    implicitHeight: Theme.itemHeight
    radius: Theme.radiusPill
    color: pointer.containsMouse ? Theme.surfaceContainerHigh : "transparent"
    scale: pointer.pressed ? 0.9 : 1

    Behavior on color {
        ColorAnimation { duration: Theme.motionFast }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionFast
            easing.type: Easing.OutCubic
        }
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: 18
        source: root.trayItem.icon
        asynchronous: true
        mipmap: true
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: event => {
            if (event.button === Qt.RightButton
                    || (event.button === Qt.LeftButton && root.trayItem.onlyMenu)) {
                root.trayItem.display(
                    root.hostWindow,
                    root.mapToItem(null, 0, root.height).x,
                    root.mapToItem(null, 0, root.height).y
                );
            } else if (event.button === Qt.MiddleButton) {
                root.trayItem.secondaryActivate();
            } else {
                root.trayItem.activate();
            }
        }

        onWheel: event => {
            const horizontal = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y);
            const delta = horizontal ? event.angleDelta.x : event.angleDelta.y;
            root.trayItem.scroll(delta, horizontal);
        }
    }
}

