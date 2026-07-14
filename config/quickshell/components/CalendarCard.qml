import QtQuick
import QtQuick.Layouts
import "../theme"

Surface {
    id: root

    readonly property date today: new Date()
    property date shownMonth: new Date(today.getFullYear(), today.getMonth(), 1)
    readonly property int mondayOffset: (shownMonth.getDay() + 6) % 7
    readonly property date gridStart: new Date(
        shownMonth.getFullYear(), shownMonth.getMonth(), 1 - mondayOffset
    )

    implicitHeight: 278
    color: Theme.surfaceContainer

    ColumnLayout {
        anchors {
            fill: parent
            margins: Theme.space12
        }
        spacing: Theme.space8

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: Qt.formatDate(root.shownMonth, "MMMM yyyy")
                font.pixelSize: Theme.fontTitle
                font.weight: Font.DemiBold
            }

            StyledText {
                text: "TODAY"
                color: monthPointer.containsMouse
                    ? Theme.primary : Theme.foregroundSurfaceVariant
                font.pixelSize: 10
                font.weight: Font.Bold

                MouseArea {
                    id: monthPointer
                    anchors.fill: parent
                    anchors.margins: -Theme.space8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shownMonth = new Date(
                        root.today.getFullYear(), root.today.getMonth(), 1
                    )
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: Theme.space4
            columnSpacing: Theme.space4

            Repeater {
                model: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

                StyledText {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    text: modelData
                    color: Theme.outline
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Repeater {
                model: 42

                Rectangle {
                    required property int index
                    readonly property date cellDate: new Date(
                        root.gridStart.getFullYear(),
                        root.gridStart.getMonth(),
                        root.gridStart.getDate() + index
                    )
                    readonly property bool isToday:
                        cellDate.toDateString() === root.today.toDateString()
                    readonly property bool inMonth:
                        cellDate.getMonth() === root.shownMonth.getMonth()

                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    radius: Theme.radiusPill
                    color: isToday ? Theme.primary : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: parent.cellDate.getDate()
                        color: parent.isToday ? Theme.foregroundPrimary
                            : parent.inMonth ? Theme.foregroundSurface
                            : Theme.outline
                        font.pixelSize: Theme.fontSmall
                        font.weight: parent.isToday ? Font.Bold : Font.Medium
                    }
                }
            }
        }
    }
}
