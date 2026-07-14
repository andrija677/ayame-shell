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

    implicitWidth: label.implicitWidth + Theme.space16
    implicitHeight: Theme.itemHeight
    radius: Theme.radiusPill
    color: pointer.containsMouse ? Theme.surfaceContainerHigh : "transparent"
    scale: pointer.pressed ? 0.94 : 1

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Behavior on color {
        ColorAnimation { duration: Theme.motionFast }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionFast
            easing.type: Theme.easeEnter
        }
    }

    StyledText {
        id: label
        anchors.centerIn: parent
        text: !root.audio ? "AUDIO"
            : root.muted ? "MUTE"
            : root.volumePercent + "%"
        font.family: root.audio && !root.muted
            ? Theme.fontFamilyNumeric : Theme.fontFamily
        color: root.muted ? Theme.error : Theme.foregroundSurfaceVariant
        font.pixelSize: Theme.fontSmall
        font.weight: Theme.fontWeightLabel

        Behavior on color {
            ColorAnimation { duration: Theme.motionFast }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.audio !== null
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: root.audio.muted = !root.audio.muted
        onWheel: event => {
            const direction = event.angleDelta.y > 0 ? 1 : -1;
            root.audio.volume = Math.max(
                0,
                Math.min(1, root.audio.volume + direction * 0.05)
            );
        }
    }
}
