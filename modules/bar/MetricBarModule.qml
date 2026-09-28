import QtQuick
import "../../components"
import "../../services" as Services

// Shared projection for the system metric bar modules. Owns the
// threshold -> indicator colour, stale -> warning, and availability text
// policy so a metric module is only a descriptor.
BarChip {
    id: root

    required property string metricId
    property string shortLabel: ""
    property string unit: "%"
    property real warnThreshold: 80
    property real critThreshold: 90

    readonly property var metricState: Services.SystemMetricsService[metricId]
    readonly property bool available: metricState.availability === "available"
    readonly property bool unavailable: metricState.availability === "unavailable"
    readonly property bool stale: metricState.freshness === "stale"
    readonly property bool highUsage: available && metricState.value > warnThreshold
    readonly property bool criticalUsage: available && metricState.value > critThreshold
    readonly property color usageColor: unavailable || criticalUsage
        ? Services.ThemeService.theme.tokens.error
        : (highUsage || stale ? Services.ThemeService.theme.tokens.warning
            : Services.ThemeService.theme.tokens.on_surface_indicator)

    visible: Services.ConfigService.config.bar.metrics[metricId]
    text: available ? `${metricState.value}${unit}`
        : (unavailable ? `${shortLabel}!` : `${shortLabel}...`)
    iconColor: usageColor
    textColor: highUsage || stale || unavailable
        ? usageColor : Services.ThemeService.theme.tokens.on_surface_subdued
    warning: stale
    hoverText: Services.SystemMetricsService[metricId + "HoverText"]
    configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
    configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
    configuredFontSize: Services.ConfigService.config.appearance.fontSize
}
