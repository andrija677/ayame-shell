import QtQuick
import Quickshell
import "../services"
import "../settings"
import "../theme"

Rectangle {
    id: root
    required property var hostWindow
    readonly property bool open: details.panelOpen
    visible: WeatherService.configured
    implicitWidth: visible ? label.implicitWidth + Theme.space16 : 0
    implicitHeight: Theme.itemHeight
    radius: Theme.radiusPill
    color: pointer.containsMouse || open
        ? Theme.surfaceContainerHigh : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

    function closePanel() {
        details.closePanel();
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        text: WeatherService.hasData
            ? Math.round(WeatherService.forecast.current.temperature_2m)
                + (ShellConfig.weatherTemperatureUnit === "celsius" ? "°C" : "°F")
            : WeatherService.loading ? "WEATHER…" : "WEATHER"
        color: WeatherService.error.length > 0
            ? Theme.warning : Theme.foregroundSurfaceVariant
        font.family: WeatherService.hasData
            ? Theme.fontFamilyNumeric : Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        font.weight: Theme.fontWeightLabel
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                WeatherService.refresh();
            else
                details.toggle();
        }
    }

    PopupWindow {
        id: details
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
            WeatherService.refresh();
        }

        function closePanel() {
            if (!visible)
                return;
            openTimer.stop();
            panelOpen = false;
            closeTimer.restart();
        }

        anchor.window: root.hostWindow
        anchor.rect.x: Math.max(Theme.outerMargin,
            root.mapToItem(null, 0, 0).x - width + root.width)
        anchor.rect.y: root.hostWindow.height
        implicitWidth: 420
        implicitHeight: weatherCard.implicitHeight + Theme.space8
        color: "transparent"
        grabFocus: false
        visible: false

        onVisibleChanged: {
            if (!visible) {
                closeTimer.stop();
                panelOpen = false;
            }
        }

        Timer {
            id: openTimer
            interval: Theme.motionMapGrace
            onTriggered: details.panelOpen = true
        }

        Timer {
            id: closeTimer
            interval: Theme.motionNormal + Theme.motionUnmapGrace
            onTriggered: details.visible = false
        }

        WeatherCard {
            id: weatherCard
            y: details.panelOpen ? Theme.space8 : -Theme.space4
            width: parent.width
            opacity: details.panelOpen ? 1 : 0

            transform: Scale {
                origin.x: weatherCard.width
                origin.y: 0
                xScale: details.panelOpen ? 1 : 0.94
                yScale: details.panelOpen ? 1 : 0.86
                Behavior on xScale {
                    enabled: details.visible
                    NumberAnimation {
                        duration: Theme.motionNormal
                        easing.type: details.panelOpen
                            ? Theme.easeEnter : Theme.easeExit
                    }
                }
                Behavior on yScale {
                    enabled: details.visible
                    NumberAnimation {
                        duration: Theme.motionNormal
                        easing.type: details.panelOpen
                            ? Theme.easeEnter : Theme.easeExit
                    }
                }
            }

            Behavior on y {
                enabled: details.visible
                NumberAnimation {
                    duration: Theme.motionNormal
                    easing.type: details.panelOpen
                        ? Theme.easeEnter : Theme.easeExit
                }
            }
            Behavior on opacity {
                enabled: details.visible
                NumberAnimation { duration: Theme.motionNormal }
            }
        }
    }
}
