import QtQuick
import QtQuick.Layouts
import "../services"
import "../theme"

Surface {
    id: root

    readonly property var upcoming: EventStore.upcomingEvents(30)

    implicitHeight: upcoming.length > 0
        ? eventColumn.implicitHeight + Theme.space24 : 0
    visible: upcoming.length > 0
    color: Theme.surfaceContainer

    ColumnLayout {
        id: eventColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.space12
        }
        spacing: Theme.space8

        StyledText {
            id: heading
            text: "Upcoming"
            font.weight: Theme.fontWeightLabel
        }

        Repeater {
            model: root.upcoming.slice(0, 3)

            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Theme.space8

                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: Theme.radiusSmall
                    color: modelData.daysUntil <= modelData.reminderDays
                        ? Theme.primary : Theme.surfaceContainerHigh

                    StyledText {
                        anchors.centerIn: parent
                        text: parent.parent.modelData.occurrence.getDate()
                        font.family: Theme.fontFamilyNumeric
                        color: parent.parent.modelData.daysUntil
                                <= parent.parent.modelData.reminderDays
                            ? Theme.foregroundPrimary
                            : Theme.foregroundSurface
                        font.weight: Theme.fontWeightTitle
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space2
                    StyledText {
                        Layout.fillWidth: true
                        text: parent.parent.modelData.title
                        font.weight: Theme.fontWeightLabel
                        elide: Text.ElideRight
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: parent.parent.modelData.daysUntil === 0 ? "Today"
                            : parent.parent.modelData.daysUntil === 1 ? "Tomorrow"
                            : "In " + parent.parent.modelData.daysUntil + " days"
                        color: Theme.foregroundSurfaceVariant
                        font.pixelSize: Theme.fontSmall
                    }
                }

                StyledText {
                    text: Qt.formatDate(modelData.occurrence, "d MMM")
                    color: Theme.outline
                    font.pixelSize: Theme.fontSmall
                }
            }
        }
    }
}
