import QtQuick
import "../../components"
import "../../services" as Services

BarChip {
  readonly property bool highUsage: Services.SystemMetricsService.cpu.availability === "available"
    && Services.SystemMetricsService.cpu.value > 80
  readonly property bool criticalUsage: Services.SystemMetricsService.cpu.availability === "available"
    && Services.SystemMetricsService.cpu.value > 90
  readonly property color usageColor: Services.SystemMetricsService.cpu.availability === "unavailable"
    || criticalUsage
      ? Services.ThemeService.theme.tokens.error
      : (highUsage ? Services.ThemeService.theme.tokens.warning : Services.ThemeService.theme.tokens.secondary)

  visible: Services.ConfigService.config.bar.metrics.cpu
  icon: "memory"
  text: Services.SystemMetricsService.cpu.availability === "available"
    ? `${Services.SystemMetricsService.cpu.value}%`
    : (Services.SystemMetricsService.cpu.availability === "unavailable" ? "CPU!" : "CPU...")
  iconColor: usageColor
  textColor: highUsage || Services.SystemMetricsService.cpu.availability === "unavailable"
    ? usageColor : Services.ThemeService.theme.tokens.on_surface_disabled
  warning: Services.SystemMetricsService.cpu.freshness === "stale"
  hoverText: Services.SystemMetricsService.cpuHoverText
  configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
  configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
  configuredFontSize: Services.ConfigService.config.appearance.fontSize
}
