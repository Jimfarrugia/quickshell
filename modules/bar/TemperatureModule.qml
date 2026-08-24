import QtQuick
import "../../components"
import "../../services" as Services

BarChip {
  readonly property bool highTemperature: Services.SystemMetricsService.temperature.availability === "available"
    && Services.SystemMetricsService.temperature.value > 70
  readonly property bool criticalTemperature: Services.SystemMetricsService.temperature.availability === "available"
    && Services.SystemMetricsService.temperature.value > 80
  readonly property color temperatureColor: Services.SystemMetricsService.temperature.availability === "unavailable"
    || criticalTemperature
      ? Services.ThemeService.theme.tokens.error
      : (highTemperature ? Services.ThemeService.theme.tokens.warning : Services.ThemeService.theme.tokens.accentSecondary)

  visible: Services.ConfigService.config.bar.metrics.temperature
  icon: "thermostat"
  text: Services.SystemMetricsService.temperature.availability === "available"
    ? `${Services.SystemMetricsService.temperature.value}°C`
    : (Services.SystemMetricsService.temperature.availability === "unavailable" ? "Temp!" : "Temp...")
  iconColor: temperatureColor
  textColor: highTemperature || Services.SystemMetricsService.temperature.availability === "unavailable"
    ? temperatureColor : Services.ThemeService.theme.tokens.textSecondary
  warning: Services.SystemMetricsService.temperature.freshness === "stale"
  hoverText: Services.SystemMetricsService.temperatureHoverText
  configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
  configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
  configuredFontSize: Services.ConfigService.config.appearance.fontSize
}
