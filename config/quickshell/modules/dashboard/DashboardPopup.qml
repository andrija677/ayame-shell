import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../components"
import "../../settings"
import "../../theme"

PanelWindow {
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

    screen: hostWindow.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "ayame-shell-dashboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible
        ? WlrLayershell.OnDemand : WlrLayershell.None

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

    MouseArea { anchors.fill: parent; onClicked: root.closePanel() }

    Surface {
        id: dashboard
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: root.hostWindow.height - Theme.space4
                + (Theme.space8 + Theme.space4) * motion.value
        }
        width: 390
        implicitHeight: content.implicitHeight + Theme.space16
        opacity: motion.value
        radius: Theme.radiusLarge
        color: Theme.surface

        MouseArea { anchors.fill: parent }

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
                margins: Theme.space8
            }
            spacing: Theme.space8

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
