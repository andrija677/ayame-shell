import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../components"
import "../../settings"
import "../../theme"

PopupWindow {
    id: root

    required property var hostWindow
    readonly property bool open: panelOpen
    property bool panelOpen: false

    MotionProgress { id: motion; open: root.panelOpen }

    function toggle() {
        if (panelOpen)
            closePanel();
        else
            openPanel();
    }

    function openPanel() {
        closeTimer.stop();
        panelOpen = false;
        visible = true;
        openTimer.restart();
    }

    function closePanel() {
        openTimer.stop();
        panelOpen = false;
        closeTimer.restart();
    }

    anchor.window: hostWindow
    anchor.rect.x: Math.round((hostWindow.width - width) / 2)
    anchor.rect.y: hostWindow.height
    implicitWidth: 390
    implicitHeight: dashboard.implicitHeight + Theme.space8
    color: "transparent"
    grabFocus: false

    HyprlandFocusGrab {
        windows: [root, root.hostWindow]
        active: root.visible
        onCleared: {
            if (root.panelOpen)
                root.closePanel();
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.closePanel()
    }

    onVisibleChanged: {
        if (!visible) {
            closeTimer.stop();
            panelOpen = false;
        }
    }

    Timer {
        id: openTimer
        interval: Theme.motionMapGrace
        onTriggered: root.panelOpen = true
    }

    Timer {
        id: closeTimer
        interval: Theme.motionNormal + Theme.motionUnmapGrace
        onTriggered: root.visible = false
    }

    Surface {
        id: dashboard
        width: parent.width
        implicitHeight: content.implicitHeight + Theme.space24
        y: -Theme.space4 + (Theme.space8 + Theme.space4) * motion.value
        opacity: motion.value
        radius: Theme.radiusLarge
        color: Theme.surface

        transform: Scale {
            id: panelScale
            origin.x: dashboard.width / 2
            origin.y: 0
            xScale: 0.94 + 0.06 * motion.value
            yScale: 0.82 + 0.18 * motion.value
        }

        ColumnLayout {
            id: content
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Theme.space12
            }
            spacing: Theme.space12

            StyledText {
                text: Qt.formatDateTime(new Date(), "dddd, d MMMM")
                font.pixelSize: Theme.fontTitle
                font.weight: Theme.fontWeightLabel
            }

            MediaCard { Layout.fillWidth: true }
            WeatherCard { Layout.fillWidth: true }
            CalendarCard {
                Layout.fillWidth: true
                hostWindow: root.hostWindow
            }
            UpcomingEventsCard { Layout.fillWidth: true }

            NotificationCenterCard { Layout.fillWidth: true }
        }
    }

}
