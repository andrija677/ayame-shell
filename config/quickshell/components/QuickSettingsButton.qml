import QtQuick
import "../theme"

Rectangle {
    id: root

    property bool active: false
    signal activated()

    implicitWidth: Theme.itemHeight
    implicitHeight: Theme.itemHeight
    radius: Theme.radiusPill
    color: active ? Theme.primaryContainer
        : pointer.containsMouse ? Theme.surfaceContainerHigh
        : "transparent"
    scale: pointer.pressed ? 0.92 : 1

    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    Behavior on scale {
        NumberAnimation {
            duration: Theme.motionFast
            easing.type: Easing.OutCubic
        }
    }

    Canvas {
        id: settingsIcon
        anchors.centerIn: parent
        width: 16
        height: 16

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = root.active
                ? Theme.foregroundPrimaryContainer
                : Theme.foregroundSurfaceVariant;
            ctx.fillStyle = ctx.strokeStyle;
            ctx.lineWidth = 1.6;
            ctx.lineCap = "round";

            const rows = [[4, 5], [11, 8], [7, 11]];
            for (let row of rows) {
                ctx.beginPath();
                ctx.moveTo(2, row[1]);
                ctx.lineTo(14, row[1]);
                ctx.stroke();
                ctx.beginPath();
                ctx.arc(row[0], row[1], 1.8, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        Connections {
            target: root
            function onActiveChanged() { settingsIcon.requestPaint(); }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
