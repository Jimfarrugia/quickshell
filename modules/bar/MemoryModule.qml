import QtQuick
import "../../components"
import "../../services" as Services

BarChip {
  readonly property bool highUsage: Services.SystemMetricsService.memory.availability === "available"
    && Services.SystemMetricsService.memory.value > 80
  readonly property bool criticalUsage: Services.SystemMetricsService.memory.availability === "available"
    && Services.SystemMetricsService.memory.value > 90
  readonly property color usageColor: Services.SystemMetricsService.memory.availability === "unavailable"
    || criticalUsage
      ? Services.ThemeService.theme.tokens.error
      : (highUsage ? Services.ThemeService.theme.tokens.warning : Services.ThemeService.theme.tokens.secondary)

  visible: Services.ConfigService.config.bar.metrics.memory
  icon: "memory_alt"
  text: Services.SystemMetricsService.memory.availability === "available"
    ? `${Services.SystemMetricsService.memory.value}%`
    : (Services.SystemMetricsService.memory.availability === "unavailable" ? "Mem!" : "Mem...")
  iconColor: usageColor
  textColor: highUsage || Services.SystemMetricsService.memory.availability === "unavailable"
    ? usageColor : Services.ThemeService.theme.tokens.on_surface_disabled
  warning: Services.SystemMetricsService.memory.freshness === "stale"
  hoverText: Services.SystemMetricsService.memoryHoverText
  configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
  configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
  configuredFontSize: Services.ConfigService.config.appearance.fontSize
}
