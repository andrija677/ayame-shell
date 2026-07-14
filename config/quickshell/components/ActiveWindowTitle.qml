import QtQuick
import Quickshell.Hyprland
import "../theme"

Item {
    id: root

    readonly property string windowTitle: Hyprland.activeToplevel?.title ?? ""
    readonly property bool overflowing: titleLabel.implicitWidth > width

    visible: windowTitle.length > 0
    clip: true

    onWindowTitleChanged: {
        titleLabel.x = 0;
        Qt.callLater(() => {
            if (root.overflowing)
                marquee.restart();
        });
    }

    StyledText {
        id: titleLabel
        anchors.verticalCenter: parent.verticalCenter
        text: root.windowTitle
        color: Theme.foregroundSurfaceVariant
        font.pixelSize: Theme.fontSmall
        font.weight: Theme.fontWeightBody
        maximumLineCount: 1
        verticalAlignment: Text.AlignVCenter
    }

    SequentialAnimation {
        id: marquee
        running: root.visible && root.overflowing
        loops: Animation.Infinite

        PauseAnimation { duration: 1100 }
        NumberAnimation {
            target: titleLabel
            property: "x"
            to: -(titleLabel.implicitWidth - root.width)
            duration: Math.max(900,
                (titleLabel.implicitWidth - root.width) * 28)
            easing.type: Easing.InOutCubic
        }
        PauseAnimation { duration: 1400 }
        NumberAnimation {
            target: titleLabel
            property: "x"
            to: 0
            duration: Math.max(700,
                (titleLabel.implicitWidth - root.width) * 22)
            easing.type: Easing.InOutCubic
        }

        onRunningChanged: {
            if (!running)
                titleLabel.x = 0;
        }
    }
}
