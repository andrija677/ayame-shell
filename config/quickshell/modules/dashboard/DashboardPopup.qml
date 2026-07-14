import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
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
        visible = true;
        panelOpen = true;
    }

    function closePanel() {
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

    onVisibleChanged: {
        if (!visible) {
            closeTimer.stop();
            panelOpen = false;
        }
    }

    Timer {
        id: closeTimer
        interval: Theme.motionNormal
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
                NumberAnimation {
                    duration: root.panelOpen
                        ? Theme.motionSlow : Theme.motionNormal
                    easing.type: root.panelOpen
                        ? Theme.easeEnter : Theme.easeExit
                }
            }

            Behavior on yScale {
                NumberAnimation {
                    duration: root.panelOpen
                        ? Theme.motionSlow : Theme.motionNormal
                    easing.type: root.panelOpen
                        ? Theme.easeEnter : Theme.easeExit
                }
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: root.panelOpen
                    ? Theme.motionSlow : Theme.motionNormal
                easing.type: root.panelOpen
                    ? Theme.easeEnter : Theme.easeExit
            }
        }

        Behavior on opacity {
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

            Surface {
                Layout.fillWidth: true
                implicitHeight: 54
                color: Theme.surfaceContainer

                StyledText {
                    anchors.centerIn: parent
                    text: "Notifications will join when Ayame owns the session"
                    color: Theme.foregroundSurfaceVariant
                    font.pixelSize: Theme.fontSmall
                }
            }
        }
    }

}
