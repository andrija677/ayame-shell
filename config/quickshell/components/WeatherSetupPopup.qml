import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../settings"
import "../theme"

PopupWindow {
    id: root
    required property var hostWindow

    function open() {
        query.text = "";
        WeatherService.searchResults = [];
        visible = true;
        query.forceActiveFocus();
    }

    anchor.window: hostWindow
    anchor.rect.x: Math.round((hostWindow.width - width) / 2)
    anchor.rect.y: hostWindow.height + 72
    implicitWidth: 380
    implicitHeight: setupSurface.implicitHeight
    color: "transparent"
    grabFocus: true
    visible: false

    Surface {
        id: setupSurface
        width: parent.width
        implicitHeight: setupColumn.implicitHeight + Theme.space24
        color: Theme.surfaceContainerHigh

        ColumnLayout {
            id: setupColumn
            anchors { fill: parent; margins: Theme.space12 }
            spacing: Theme.space8

            StyledText {
                text: "Weather location"
                font.pixelSize: Theme.fontTitle
                font.weight: Theme.fontWeightLabel
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.radiusSmall
                    color: Theme.surfaceContainer
                    border.color: query.activeFocus ? Theme.primary : Theme.outlineVariant
                    TextInput {
                        id: query
                        anchors { fill: parent; margins: Theme.space12 }
                        color: Theme.foregroundSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontNormal
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        clip: true
                        onAccepted: WeatherService.searchCity(text)
                    }
                }
                Rectangle {
                    implicitWidth: 70
                    implicitHeight: 34
                    radius: Theme.radiusPill
                    color: Theme.primaryContainer
                    StyledText { anchors.centerIn: parent; text: "SEARCH"; font.pixelSize: 9 }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WeatherService.searchCity(query.text)
                    }
                }
            }

            StyledText {
                visible: WeatherService.searching || WeatherService.error.length > 0
                text: WeatherService.searching ? "Searching…" : WeatherService.error
                color: WeatherService.error.length > 0 ? Theme.warning : Theme.outline
                font.pixelSize: Theme.fontSmall
            }

            Repeater {
                id: resultRepeater
                property var setupPopup: root
                model: WeatherService.searchResults
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: Theme.radiusSmall
                    color: resultPointer.containsMouse
                        ? Theme.surfaceContainer : "transparent"
                    StyledText {
                        anchors { fill: parent; margins: Theme.space8 }
                        text: parent.modelData.name
                            + (parent.modelData.admin1 ? ", " + parent.modelData.admin1 : "")
                            + " • " + parent.modelData.country
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        id: resultPointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            WeatherService.selectLocation(parent.modelData);
                            resultRepeater.setupPopup.visible = false;
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8
                StyledText {
                    Layout.fillWidth: true
                    visible: WeatherService.configured
                    text: "FORGET LOCATION"
                    color: forgetPointer.containsMouse ? Theme.error : Theme.outline
                    font.pixelSize: 9
                    font.weight: Theme.fontWeightTitle
                    MouseArea {
                        id: forgetPointer
                        anchors { fill: parent; margins: -Theme.space8 }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            WeatherService.forgetLocation();
                            root.visible = false;
                        }
                    }
                }
                StyledText {
                    text: "CANCEL"
                    MouseArea {
                        anchors { fill: parent; margins: -Theme.space8 }
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.visible = false
                    }
                }
            }
        }
    }
}
