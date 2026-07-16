import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../theme"

Rectangle {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink?.audio ?? null
    readonly property bool muted: audio?.muted ?? false
    readonly property int volumePercent: Math.round((audio?.volume ?? 0) * 100)
    readonly property string volumeIcon: !audio || muted ? "󰝟"
        : volumePercent < 34 ? "󰕿"
        : volumePercent < 67 ? "󰖀" : "󰕾"
    property bool feedbackVisible: false

    implicitWidth: feedbackVisible ? 96 : Theme.itemHeight
    implicitHeight: Theme.itemHeight
    radius: Theme.radiusPill
    color: pointer.containsMouse || feedbackVisible
        ? Theme.surfaceContainerHigh : "transparent"
    scale: pointer.pressed ? 0.94 : 1

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Behavior on color {
        ColorAnimation { duration: Theme.motionFast }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.motionNormal
            easing.type: root.feedbackVisible ? Theme.easeEnter : Theme.easeExit
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionFast
            easing.type: Theme.easeEnter
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: Theme.space6

        StyledText {
            text: root.volumeIcon
            font.family: Theme.fontFamilyNumeric
            color: root.muted ? Theme.error : Theme.foregroundSurfaceVariant
            font.pixelSize: 16
            font.weight: Theme.fontWeightLabel

            Behavior on color {
                ColorAnimation { duration: Theme.motionFast }
            }
        }

        Item {
            Layout.preferredWidth: root.feedbackVisible ? 48 : 0
            implicitHeight: root.implicitHeight
            clip: true
            opacity: root.feedbackVisible ? 1 : 0

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Theme.motionNormal
                    easing.type: root.feedbackVisible
                        ? Theme.easeEnter : Theme.easeExit
                }
            }
            Behavior on opacity {
                NumberAnimation { duration: Theme.motionFast }
            }

            StyledText {
                anchors.centerIn: parent
                text: root.muted ? "Muted" : root.volumePercent + "%"
                font.family: root.muted
                    ? Theme.fontFamily : Theme.fontFamilyNumeric
                color: root.muted
                    ? Theme.error : Theme.foregroundSurfaceVariant
                font.pixelSize: Theme.fontSmall
                font.weight: Theme.fontWeightLabel
            }
        }
    }

    Timer {
        id: feedbackTimer
        interval: 2500
        onTriggered: root.feedbackVisible = false
    }

    function revealFeedback() {
        feedbackVisible = true;
        feedbackTimer.restart();
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.audio !== null
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {
            root.audio.muted = !root.audio.muted;
            root.revealFeedback();
        }
        onWheel: event => {
            const direction = event.angleDelta.y > 0 ? 1 : -1;
            root.audio.volume = Math.max(
                0,
                Math.min(1, root.audio.volume + direction * 0.05)
            );
            root.revealFeedback();
            event.accepted = true;
        }
    }
}
