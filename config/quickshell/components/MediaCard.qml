import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../theme"

Surface {
    id: root

    readonly property var player: {
        const players = Mpris.players.values;
        for (let candidate of players) {
            if (candidate.isPlaying)
                return candidate;
        }
        return players.length > 0 ? players[0] : null;
    }
    readonly property real progress: {
        progressTimer.tick;
        if (!player?.positionSupported || !player?.lengthSupported
                || player.length <= 0)
            return 0;
        return Math.max(0, Math.min(1, player.position / player.length));
    }

    function formatTime(seconds) {
        if (!Number.isFinite(seconds) || seconds < 0)
            return "--:--";
        const whole = Math.floor(seconds);
        const minutes = Math.floor(whole / 60);
        return minutes + ":" + String(whole % 60).padStart(2, "0");
    }

    implicitHeight: 124
    color: Theme.surfaceContainer

    Timer {
        id: progressTimer
        property int tick: 0
        interval: 1000
        repeat: true
        running: root.player?.isPlaying ?? false
        onTriggered: tick++
    }

    RowLayout {
        anchors {
            fill: parent
            margins: Theme.space12
        }
        spacing: Theme.space12

        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 76
            implicitHeight: 76
            radius: Theme.radiusMedium
            color: Theme.surfaceContainerHigh
            clip: true

            Image {
                id: albumArt
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }

            StyledText {
                anchors.centerIn: parent
                text: "♪"
                visible: albumArt.status !== Image.Ready
                color: Theme.primary
                font.pixelSize: 28
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.space8

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Nothing playing"
                font.pixelSize: Theme.fontTitle
                font.weight: Theme.fontWeightLabel
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackArtist || "Media controls will appear here"
                color: Theme.foregroundSurfaceVariant
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                visible: (root.player?.lengthSupported ?? false)
                    && (root.player?.positionSupported ?? false)
                spacing: Theme.space6

                StyledText {
                    text: root.formatTime(root.player?.position ?? -1)
                    font.family: Theme.fontFamilyNumeric
                    color: Theme.outline
                    font.pixelSize: 9
                }

                Rectangle {
                    id: progressTrack
                    Layout.fillWidth: true
                    implicitHeight: 4
                    radius: 2
                    color: Theme.outlineVariant

                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: parent.radius
                        color: Theme.primary
                    }
                    MouseArea {
                        anchors { fill: parent; margins: -Theme.space6 }
                        enabled: root.player?.canSeek ?? false
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: event => root.player.position
                            = root.player.length * event.x / width
                    }
                }

                StyledText {
                    text: root.formatTime(root.player?.length ?? -1)
                    font.family: Theme.fontFamilyNumeric
                    color: Theme.outline
                    font.pixelSize: 9
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Theme.space6

                Repeater {
                    model: [
                        { label: "‹", enabled: root.player?.canGoPrevious ?? false,
                            action: () => root.player.previous() },
                        { label: root.player?.isPlaying ? "PAUSE" : "PLAY",
                            enabled: root.player?.canTogglePlaying ?? false,
                            action: () => root.player.togglePlaying() },
                        { label: "›", enabled: root.player?.canGoNext ?? false,
                            action: () => root.player.next() }
                    ]

                    Rectangle {
                        required property var modelData
                        implicitWidth: modelData.label.length > 1 ? 42 : 32
                        implicitHeight: 26
                        radius: Theme.radiusPill
                        color: controlPointer.containsMouse
                            ? Theme.primary : Theme.primaryContainer
                        visible: modelData.enabled

                        StyledText {
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: controlPointer.containsMouse
                                ? Theme.foregroundPrimary
                                : Theme.foregroundPrimaryContainer
                            font.pixelSize: parent.modelData.label.length > 1 ? 9 : 14
                            font.weight: Theme.fontWeightTitle
                        }
                        MouseArea {
                            id: controlPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.action()
                        }
                    }
                }
            }
        }
    }
}
