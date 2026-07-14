import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "../../components"
import "../../theme"

PopupWindow {
    id: root

    required property var hostWindow
    readonly property bool open: panelOpen
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink?.audio ?? null
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryAvailable: battery?.isPresent
        && battery?.isLaptopBattery
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

    function setVolumeFromX(position) {
        if (!audio)
            return;
        audio.volume = Math.max(0, Math.min(1, position / volumeTrack.width));
    }

    anchor.window: hostWindow
    anchor.rect.x: hostWindow.width - width - Theme.outerMargin
    anchor.rect.y: hostWindow.height
    implicitWidth: 340
    implicitHeight: panel.implicitHeight + Theme.space8
    color: "transparent"
    grabFocus: false

    onVisibleChanged: {
        if (!visible) {
            closeTimer.stop();
            panelOpen = false;
        }
    }

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    Timer {
        id: closeTimer
        interval: Theme.motionNormal
        onTriggered: root.visible = false
    }

    Surface {
        id: panel
        width: parent.width
        implicitHeight: content.implicitHeight + Theme.space24
        y: root.panelOpen ? Theme.space8 : -Theme.space4
        opacity: root.panelOpen ? 1 : 0
        radius: Theme.radiusLarge
        color: Theme.surface

        transform: Scale {
            id: panelScale
            origin.x: panel.width
            origin.y: 0
            xScale: root.panelOpen ? 1 : 0.92
            yScale: root.panelOpen ? 1 : 0.84

            Behavior on xScale {
                NumberAnimation {
                    duration: root.panelOpen ? Theme.motionSlow : Theme.motionNormal
                    easing.type: root.panelOpen ? Easing.OutCubic : Easing.InCubic
                }
            }
            Behavior on yScale {
                NumberAnimation {
                    duration: root.panelOpen ? Theme.motionSlow : Theme.motionNormal
                    easing.type: root.panelOpen ? Easing.OutCubic : Easing.InCubic
                }
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: root.panelOpen ? Theme.motionSlow : Theme.motionNormal
                easing.type: root.panelOpen ? Easing.OutCubic : Easing.InCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.motionNormal
                easing.type: root.panelOpen ? Easing.OutCubic : Easing.InCubic
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
                text: "Quick Settings"
                font.pixelSize: Theme.fontTitle
                font.weight: Font.DemiBold
            }

            Surface {
                Layout.fillWidth: true
                implicitHeight: 82
                color: Theme.surfaceContainer

                ColumnLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    spacing: Theme.space8

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: "Volume"; Layout.fillWidth: true }
                        StyledText {
                            text: root.audio?.muted ? "MUTED"
                                : Math.round((root.audio?.volume ?? 0) * 100) + "%"
                            color: root.audio?.muted
                                ? Theme.error : Theme.foregroundSurfaceVariant
                            font.pixelSize: Theme.fontSmall
                            font.weight: Font.DemiBold
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space8

                        Rectangle {
                            implicitWidth: 42
                            implicitHeight: 24
                            radius: Theme.radiusPill
                            color: mutePointer.containsMouse
                                ? Theme.surfaceContainerHigh : "transparent"
                            StyledText {
                                anchors.centerIn: parent
                                text: root.audio?.muted ? "ON" : "MUTE"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                            }
                            MouseArea {
                                id: mutePointer
                                anchors.fill: parent
                                enabled: root.audio !== null
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.audio.muted = !root.audio.muted
                            }
                        }

                        Rectangle {
                            id: volumeTrack
                            Layout.fillWidth: true
                            implicitHeight: 6
                            radius: 3
                            color: Theme.outlineVariant

                            Rectangle {
                                width: parent.width * Math.min(1, root.audio?.volume ?? 0)
                                height: parent.height
                                radius: parent.radius
                                color: root.audio?.muted ? Theme.outline : Theme.primary
                            }
                            Rectangle {
                                x: Math.max(0, Math.min(parent.width - width,
                                    parent.width * Math.min(1, root.audio?.volume ?? 0)
                                    - width / 2))
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14
                                height: 14
                                radius: 7
                                color: root.audio?.muted ? Theme.outline : Theme.primary
                            }
                            MouseArea {
                                anchors { fill: parent; margins: -Theme.space8 }
                                enabled: root.audio !== null
                                cursorShape: Qt.PointingHandCursor
                                onPressed: event => root.setVolumeFromX(event.x)
                                onPositionChanged: event => {
                                    if (pressed)
                                        root.setVolumeFromX(event.x);
                                }
                            }
                        }
                    }
                }
            }

            Surface {
                Layout.fillWidth: true
                implicitHeight: 62
                color: Theme.surfaceContainer
                RowLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    StyledText { text: "Network"; Layout.fillWidth: true }
                    StyledText {
                        text: Networking.connectivity === NetworkConnectivity.Full
                            ? "CONNECTED"
                            : Networking.connectivity === NetworkConnectivity.Limited
                                || Networking.connectivity === NetworkConnectivity.Portal
                                ? "LIMITED" : "OFFLINE"
                        color: Networking.connectivity === NetworkConnectivity.Full
                            ? Theme.success
                            : Networking.connectivity === NetworkConnectivity.None
                                ? Theme.error : Theme.warning
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.DemiBold
                    }
                }
            }

            Surface {
                Layout.fillWidth: true
                implicitHeight: root.batteryAvailable ? 62 : 0
                visible: root.batteryAvailable
                color: Theme.surfaceContainer
                RowLayout {
                    anchors { fill: parent; margins: Theme.space12 }
                    StyledText { text: "Battery"; Layout.fillWidth: true }
                    StyledText {
                        text: Math.round(root.battery?.percentage ?? 0) + "%"
                        color: Theme.foregroundSurfaceVariant
                        font.pixelSize: Theme.fontSmall
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
