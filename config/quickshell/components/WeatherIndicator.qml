import QtQuick
import "../services"
import "../settings"
import "../theme"

Rectangle {
    id: root
    visible: WeatherService.configured
    implicitWidth: visible ? label.implicitWidth + Theme.space16 : 0
    implicitHeight: Theme.itemHeight
    radius: Theme.radiusPill
    color: "transparent"

    StyledText {
        id: label
        anchors.centerIn: parent
        text: WeatherService.hasData
            ? Math.round(WeatherService.forecast.current.temperature_2m)
                + (ShellConfig.weatherTemperatureUnit === "celsius" ? "°C" : "°F")
            : WeatherService.loading ? "WEATHER…" : "WEATHER"
        color: WeatherService.error.length > 0
            ? Theme.warning : Theme.foregroundSurfaceVariant
        font.family: WeatherService.hasData
            ? Theme.fontFamilyNumeric : Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        font.weight: Theme.fontWeightLabel
    }
}
