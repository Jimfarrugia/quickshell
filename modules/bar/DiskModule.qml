import QtQuick
import "../../components"
import "../../services" as Services

BarChip {
  readonly property bool highUsage: Services.SystemMetricsService.disk.availability === "available"
    && Services.SystemMetricsService.disk.value > 80
  readonly property bool criticalUsage: Services.SystemMetricsService.disk.availability === "available"
    && Services.SystemMetricsService.disk.value > 90
  readonly property bool stale: Services.SystemMetricsService.disk.freshness === "stale"
  readonly property color usageColor: Services.SystemMetricsService.disk.availability === "unavailable"
    || criticalUsage
      ? Services.ThemeService.theme.tokens.error
      : (highUsage || stale ? Services.ThemeService.theme.tokens.warning
          : Services.ThemeService.theme.tokens.on_surface_indicator)

  visible: Services.ConfigService.config.bar.metrics.disk
  icon: "storage"
  text: Services.SystemMetricsService.disk.availability === "available"
    ? `${Services.SystemMetricsService.disk.value}%`
    : (Services.SystemMetricsService.disk.availability === "unavailable" ? "Disk!" : "Disk...")
  iconColor: usageColor
  textColor: highUsage || stale || Services.SystemMetricsService.disk.availability === "unavailable"
    ? usageColor : Services.ThemeService.theme.tokens.on_surface_subdued
  warning: stale
  hoverText: Services.SystemMetricsService.diskHoverText
  configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
  configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
  configuredFontSize: Services.ConfigService.config.appearance.fontSize
}
