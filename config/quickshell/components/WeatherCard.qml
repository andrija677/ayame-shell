import QtQuick
import QtQuick.Layouts
import "../services"
import "../settings"
import "../theme"

Surface {
    id: root
    visible: WeatherService.configured
    implicitHeight: visible ? weatherContent.implicitHeight + Theme.space24 : 0
    color: Theme.surfaceContainer

    ColumnLayout {
        id: weatherContent
        anchors { fill: parent; margins: Theme.space12 }
        spacing: Theme.space8

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.space2
                StyledText {
                    Layout.fillWidth: true
                    text: ShellConfig.weatherLocationName
                    font.pixelSize: Theme.fontTitle
                    font.weight: Theme.fontWeightLabel
                    elide: Text.ElideRight
                }
                StyledText {
                    text: WeatherService.hasData
                        ? WeatherService.weatherLabel(
                            WeatherService.forecast.current.weather_code)
                        : WeatherService.loading ? "Updating forecast…"
                        : WeatherService.error || "Waiting for weather"
                    color: Theme.foregroundSurfaceVariant
                    font.pixelSize: Theme.fontSmall
                }
            }
            StyledText {
                text: WeatherService.hasData
                    ? Math.round(WeatherService.forecast.current.temperature_2m)
                        + (ShellConfig.weatherTemperatureUnit === "celsius" ? "°C" : "°F")
                    : "--°"
                font.family: Theme.fontFamilyNumeric
                font.pixelSize: 28
                font.weight: Theme.fontWeightTitle
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: WeatherService.hasData
            spacing: Theme.space12

            StyledText {
                text: WeatherService.hasData
                    ? "FEELS " + Math.round(
                        WeatherService.forecast.current.apparent_temperature) + "°"
                    : ""
                color: Theme.foregroundSurfaceVariant
                font.family: Theme.fontFamilyNumeric
                font.pixelSize: 10
                font.weight: Theme.fontWeightLabel
            }
            StyledText {
                text: WeatherService.hasData
                    ? "WIND " + Math.round(
                        WeatherService.forecast.current.wind_speed_10m) + " "
                        + (WeatherService.forecast.current_units?.wind_speed_10m || "km/h")
                    : ""
                color: Theme.foregroundSurfaceVariant
                font.family: Theme.fontFamilyNumeric
                font.pixelSize: 10
                font.weight: Theme.fontWeightLabel
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: WeatherService.stale ? "CACHED" : "UPDATED"
                color: WeatherService.stale ? Theme.warning : Theme.success
                font.pixelSize: 9
                font.weight: Theme.fontWeightTitle
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space6
            Repeater {
                model: WeatherService.hasData
                    ? WeatherService.forecast.daily.time.slice(0, 5) : []
                ColumnLayout {
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: Theme.space2
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: index === 0 ? "TODAY"
                            : Qt.formatDate(new Date(modelData + "T12:00:00"), "ddd").toUpperCase()
                        color: Theme.outline
                        font.pixelSize: 9
                        font.weight: Theme.fontWeightTitle
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Math.round(WeatherService.forecast.daily.temperature_2m_max[index])
                            + "° / "
                            + Math.round(WeatherService.forecast.daily.temperature_2m_min[index]) + "°"
                        font.family: Theme.fontFamilyNumeric
                        font.pixelSize: 10
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: WeatherService.forecast.daily.precipitation_probability_max[index] + "%"
                        color: Theme.foregroundSurfaceVariant
                        font.family: Theme.fontFamilyNumeric
                        font.pixelSize: 9
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: WeatherService.error.length > 0 || WeatherService.stale
            text: WeatherService.error || "Cached forecast"
            color: Theme.warning
            font.pixelSize: 9
        }
    }
}
