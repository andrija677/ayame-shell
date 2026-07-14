import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../theme"

PopupWindow {
    id: root

    required property var hostWindow
    property date eventDate: new Date()

    function openFor(date) {
        eventDate = date;
        titleInput.text = "";
        yearlyToggle.checked = false;
        reminderSelector.selectedDays = 0;
        visible = true;
        titleInput.forceActiveFocus();
    }

    anchor.window: hostWindow
    anchor.rect.x: Math.round((hostWindow.width - width) / 2)
    anchor.rect.y: hostWindow.height + 72
    implicitWidth: 330
    implicitHeight: editorSurface.implicitHeight
    color: "transparent"
    grabFocus: true
    visible: false

    Surface {
        id: editorSurface
        width: parent.width
        implicitHeight: editorColumn.implicitHeight + Theme.space24
        radius: Theme.radiusLarge
        color: Theme.surfaceContainerHigh

        ColumnLayout {
            id: editorColumn
            anchors { fill: parent; margins: Theme.space12 }
            spacing: Theme.space12

            StyledText {
                text: "Add event  •  " + Qt.formatDate(root.eventDate, "d MMM yyyy")
                font.pixelSize: Theme.fontTitle
                font.weight: Font.DemiBold
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: Theme.radiusSmall
                color: Theme.surfaceContainer
                border.color: titleInput.activeFocus ? Theme.primary : Theme.outlineVariant

                TextInput {
                    id: titleInput
                    anchors { fill: parent; margins: Theme.space12 }
                    color: Theme.foregroundSurface
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontNormal
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    selectByMouse: true
                    onAccepted: saveButton.save()
                }

                StyledText {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    anchors.leftMargin: Theme.space12
                    text: "Event title"
                    color: Theme.outline
                    visible: titleInput.text.length === 0 && !titleInput.activeFocus
                }
            }

            QuickToggleTile {
                id: yearlyToggle
                Layout.fillWidth: true
                title: "Repeat yearly"
                subtitle: "Useful for birthdays and anniversaries"
                onActivated: checked = !checked
            }

            ColumnLayout {
                id: reminderSelector
                property int selectedDays: 0
                Layout.fillWidth: true
                spacing: Theme.space6

                StyledText {
                    text: "Remind me"
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space4

                    Repeater {
                        model: [
                            { label: "SAME DAY", days: 0 },
                            { label: "1 DAY BEFORE", days: 1 },
                            { label: "1 WEEK BEFORE", days: 7 }
                        ]

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 28
                            radius: Theme.radiusPill
                            color: reminderSelector.selectedDays === modelData.days
                                ? Theme.primary : reminderPointer.containsMouse
                                    ? Theme.surfaceContainer : Theme.outlineVariant

                            StyledText {
                                anchors.centerIn: parent
                                text: parent.modelData.label
                                color: reminderSelector.selectedDays === parent.modelData.days
                                    ? Theme.foregroundPrimary
                                    : Theme.foregroundSurfaceVariant
                                font.pixelSize: 8
                                font.weight: Font.Bold
                            }
                            MouseArea {
                                id: reminderPointer
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: reminderSelector.selectedDays
                                    = parent.modelData.days
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Theme.space8

                Rectangle {
                    implicitWidth: 66
                    implicitHeight: 30
                    radius: Theme.radiusPill
                    color: cancelPointer.containsMouse
                        ? Theme.surfaceContainer : "transparent"
                    StyledText { anchors.centerIn: parent; text: "CANCEL"; font.pixelSize: 9 }
                    MouseArea {
                        id: cancelPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.visible = false
                    }
                }

                Rectangle {
                    id: saveButton
                    function save() {
                        if (EventStore.addEvent(
                                titleInput.text, root.eventDate, yearlyToggle.checked,
                                reminderSelector.selectedDays))
                            root.visible = false;
                    }
                    implicitWidth: 66
                    implicitHeight: 30
                    radius: Theme.radiusPill
                    color: savePointer.containsMouse ? Theme.primary : Theme.primaryContainer
                    StyledText {
                        anchors.centerIn: parent
                        text: "SAVE"
                        color: savePointer.containsMouse
                            ? Theme.foregroundPrimary : Theme.foregroundPrimaryContainer
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                    MouseArea {
                        id: savePointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: saveButton.save()
                    }
                }
            }
        }
    }
}
