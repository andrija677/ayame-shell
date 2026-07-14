import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../settings"
import "../../theme"

PopupWindow {
    id: root

    required property var hostWindow
    readonly property bool open: panelOpen
    property bool panelOpen: false

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
    implicitWidth: 420
    implicitHeight: dashboard.implicitHeight + Theme.space8
    color: "transparent"
    // Keeping focus with the bar lets a second clock click reach toggle().
    // If the popup grabs focus, Quickshell dismisses it as an outside click
    // before Ayame can play the closing transition.
    grabFocus: false

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
        y: root.panelOpen ? Theme.space8 : -Theme.space4
        opacity: root.panelOpen ? 1 : 0
        radius: Theme.radiusLarge
        color: Theme.surface

        transform: Scale {
            id: panelScale
            origin.x: dashboard.width / 2
            origin.y: 0
            xScale: root.panelOpen ? 1 : 0.94
            yScale: root.panelOpen ? 1 : 0.82

            Behavior on xScale {
                enabled: root.visible
                NumberAnimation {
                    duration: Theme.motionNormal
                    easing.type: root.panelOpen
                        ? Theme.easeEnter : Theme.easeExit
                }
            }

            Behavior on yScale {
                enabled: root.visible
                NumberAnimation {
                    duration: Theme.motionNormal
                    easing.type: root.panelOpen
                        ? Theme.easeEnter : Theme.easeExit
                }
            }
        }

        Behavior on y {
            enabled: root.visible
            NumberAnimation {
                duration: Theme.motionNormal
                easing.type: root.panelOpen
                    ? Theme.easeEnter : Theme.easeExit
            }
        }

        Behavior on opacity {
            enabled: root.visible
            NumberAnimation {
                duration: Theme.motionNormal
                easing.type: root.panelOpen
                    ? Theme.easeEnter : Theme.easeExit
            }
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
