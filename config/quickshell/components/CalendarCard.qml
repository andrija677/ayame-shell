import QtQuick
import QtQuick.Layouts
import "../services"
import "../theme"

Surface {
    id: root

    required property var hostWindow
    readonly property date today: new Date()
    property date shownMonth: new Date(today.getFullYear(), today.getMonth(), 1)
    property date selectedDate: today
    property date pendingMonth: shownMonth
    readonly property int mondayOffset: (shownMonth.getDay() + 6) % 7
    readonly property date gridStart: new Date(
        shownMonth.getFullYear(), shownMonth.getMonth(), 1 - mondayOffset
    )

    function navigateMonth(offset) {
        pendingMonth = new Date(
            shownMonth.getFullYear(), shownMonth.getMonth() + offset, 1
        );
        monthTransition.restart();
    }

    function returnToToday() {
        pendingMonth = new Date(today.getFullYear(), today.getMonth(), 1);
        selectedDate = today;
        monthTransition.restart();
    }

    implicitHeight: 374
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

            Repeater {
                model: [
                    { label: "‹", action: () => root.navigateMonth(-1) },
                    { label: "TODAY", action: () => root.returnToToday() },
                    { label: "›", action: () => root.navigateMonth(1) }
                ]

                Rectangle {
                    required property var modelData
                    implicitWidth: modelData.label === "TODAY" ? 52 : 26
                    implicitHeight: 24
                    radius: Theme.radiusPill
                    color: navigationPointer.containsMouse
                        ? Theme.surfaceContainerHigh : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        color: navigationPointer.containsMouse
                            ? Theme.primary : Theme.foregroundSurfaceVariant
                        font.pixelSize: parent.modelData.label === "TODAY" ? 9 : 16
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: navigationPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.modelData.action()
                    }
                }
            }
        }

        GridLayout {
            id: calendarGrid
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
                    readonly property bool selected:
                        cellDate.toDateString() === root.selectedDate.toDateString()
                    readonly property bool hasEvents:
                        EventStore.eventsForDate(cellDate).length > 0

                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    radius: Theme.radiusPill
                    color: isToday ? Theme.primary : "transparent"
                    border.width: selected && !isToday ? 1 : 0
                    border.color: Theme.primary

                    StyledText {
                        anchors.centerIn: parent
                        text: parent.cellDate.getDate()
                        color: parent.isToday ? Theme.foregroundPrimary
                            : parent.inMonth ? Theme.foregroundSurface
                            : Theme.outline
                        font.pixelSize: Theme.fontSmall
                        font.weight: parent.isToday ? Font.Bold : Font.Medium
                    }

                    Rectangle {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                            bottomMargin: 2
                        }
                        width: 3
                        height: 3
                        radius: 2
                        visible: parent.hasEvents
                        color: parent.isToday
                            ? Theme.foregroundPrimary : Theme.primary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedDate = parent.cellDate
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.outlineVariant
        }

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                text: Qt.formatDate(root.selectedDate, "dddd, d MMMM")
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Rectangle {
                implicitWidth: 76
                implicitHeight: 26
                radius: Theme.radiusPill
                color: addPointer.containsMouse
                    ? Theme.primary : Theme.primaryContainer

                StyledText {
                    anchors.centerIn: parent
                    text: "+ EVENT"
                    color: addPointer.containsMouse
                        ? Theme.foregroundPrimary : Theme.foregroundPrimaryContainer
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
                MouseArea {
                    id: addPointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: eventEditor.openFor(root.selectedDate)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: selectedEvents.count === 0

            StyledText {
                Layout.fillWidth: true
                text: "No events for this day"
                color: Theme.outline
                font.pixelSize: Theme.fontSmall
            }
        }

        Repeater {
            id: selectedEvents
            model: EventStore.eventsForDate(root.selectedDate)

            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Theme.space8

                Rectangle {
                    implicitWidth: 6
                    implicitHeight: 6
                    radius: 3
                    color: Theme.primary
                }
                StyledText {
                    Layout.fillWidth: true
                    text: modelData.title
                        + (modelData.recurrence === "yearly" ? "  •  YEARLY" : "")
                    elide: Text.ElideRight
                }
                StyledText {
                    text: "×"
                    color: removePointer.containsMouse ? Theme.error : Theme.outline
                    font.pixelSize: 16
                    MouseArea {
                        id: removePointer
                        anchors { fill: parent; margins: -Theme.space6 }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: EventStore.removeEvent(parent.parent.modelData.id)
                    }
                }
            }
        }
    }

    EventEditorPopup {
        id: eventEditor
        hostWindow: root.hostWindow
    }

    SequentialAnimation {
        id: monthTransition

        NumberAnimation {
            target: calendarGrid
            property: "opacity"
            to: 0
            duration: Theme.motionFast / 2
            easing.type: Easing.InCubic
        }
        ScriptAction { script: root.shownMonth = root.pendingMonth }
        NumberAnimation {
            target: calendarGrid
            property: "opacity"
            to: 1
            duration: Theme.motionFast
            easing.type: Easing.OutCubic
        }
    }
}
