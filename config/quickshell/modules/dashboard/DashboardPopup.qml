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

    SystemClock {
        id: dashboardClock
        precision: SystemClock.Minutes
    }

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
            topMargin: -Theme.space4
                + (Theme.space8 + Theme.space4) * motion.value
        }
        width: Math.min(390, root.width - Theme.space24)
        height: Math.min(content.implicitHeight + Theme.space16,
            root.height - Theme.barHeight - Theme.space24)
        opacity: motion.value
        radius: Theme.radiusLarge
        color: Theme.surface
        clip: true

        MouseArea { anchors.fill: parent }

        transform: Scale {
            id: panelScale
            origin.x: dashboard.width / 2
            origin.y: 0
            xScale: 0.94 + 0.06 * motion.value
            yScale: 0.82 + 0.18 * motion.value
        }

        Flickable {
            id: dashboardFlickable
            anchors { fill: parent; margins: Theme.space8 }
            contentWidth: width
            contentHeight: content.implicitHeight
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: content
                width: dashboardFlickable.width
                spacing: Theme.space8

                StyledText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(dashboardClock.date, "dddd, d MMMM")
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontTitle
                    font.weight: Theme.fontWeightTitle
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

        Rectangle {
            anchors {
                top: dashboardFlickable.top
                bottom: dashboardFlickable.bottom
                right: dashboardFlickable.right
            }
            width: 3
            radius: Theme.radiusPill
            color: Theme.translucent(Theme.outlineVariant, 0.3)
            visible: dashboardFlickable.interactive

            Rectangle {
                width: parent.width
                height: Math.max(36, parent.height
                    * dashboardFlickable.height / dashboardFlickable.contentHeight)
                y: dashboardFlickable.contentY
                    / Math.max(1, dashboardFlickable.contentHeight
                        - dashboardFlickable.height)
                    * (parent.height - height)
                radius: Theme.radiusPill
                color: Theme.primary
            }
        }
    }

}
