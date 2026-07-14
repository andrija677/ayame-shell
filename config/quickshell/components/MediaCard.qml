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

    implicitHeight: 92
    color: Theme.surfaceContainer

    ColumnLayout {
        anchors {
            fill: parent
            margins: Theme.space12
        }
        spacing: Theme.space8

        StyledText {
            Layout.fillWidth: true
            text: root.player?.trackTitle || "Nothing playing"
            font.pixelSize: Theme.fontTitle
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space8

            StyledText {
                Layout.fillWidth: true
                text: root.player?.trackArtist || "Media controls will appear here"
                color: Theme.foregroundSurfaceVariant
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
            }

            Rectangle {
                implicitWidth: 32
                implicitHeight: 28
                radius: Theme.radiusPill
                color: previousPointer.containsMouse
                    ? Theme.surfaceContainerHigh : "transparent"
                visible: root.player?.canGoPrevious ?? false

                StyledText { anchors.centerIn: parent; text: "‹" }
                MouseArea {
                    id: previousPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player.previous()
                }
            }

            Rectangle {
                implicitWidth: 42
                implicitHeight: 28
                radius: Theme.radiusPill
                color: playPointer.containsMouse
                    ? Theme.primary : Theme.primaryContainer
                visible: root.player?.canTogglePlaying ?? false

                StyledText {
                    anchors.centerIn: parent
                    text: root.player?.isPlaying ? "PAUSE" : "PLAY"
                    color: playPointer.containsMouse
                        ? Theme.foregroundPrimary
                        : Theme.foregroundPrimaryContainer
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
                MouseArea {
                    id: playPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player.togglePlaying()
                }
            }

            Rectangle {
                implicitWidth: 32
                implicitHeight: 28
                radius: Theme.radiusPill
                color: nextPointer.containsMouse
                    ? Theme.surfaceContainerHigh : "transparent"
                visible: root.player?.canGoNext ?? false

                StyledText { anchors.centerIn: parent; text: "›" }
                MouseArea {
                    id: nextPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player.next()
                }
            }
        }
    }
}
