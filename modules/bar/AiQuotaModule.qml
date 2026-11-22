import QtQuick
import "../../components"
import "../../services" as Services
import "../../utils/AiQuota.mjs" as AiQuota

BarChip {
    id: root
    property var sourceScreen: null
    property string sourceSide: "left"
    readonly property var selected: Services.AiQuotaService.provider(Services.AiQuotaService.selectedProvider)
    readonly property bool current: selected.weekly.status === "ok"
    Services.AiQuotaConsumer { active: root.visible }

    text: current ? `${AiQuota.formatPercent(selected.weekly.remainingPercent)}%` : "--"
    icon: "robot_2"
    iconColor: !current || Services.AiQuotaService.operation === "failed"
        ? Services.ThemeService.theme.tokens.error
        : (selected.freshness === "stale" ? Services.ThemeService.theme.tokens.warning
            : (Services.AiQuotaService.operation === "pending"
                ? Services.ThemeService.theme.tokens.primary
                : Services.ThemeService.theme.tokens.on_surface_indicator))
    textColor: !current || Services.AiQuotaService.operation === "failed"
        ? Services.ThemeService.theme.tokens.error
        : (selected.freshness === "stale" ? Services.ThemeService.theme.tokens.warning
            : (Services.AiQuotaService.operation === "pending"
                ? Services.ThemeService.theme.tokens.primary
                : Services.ThemeService.theme.tokens.on_surface_subdued))
    warning: false
    hoverText: Services.AiQuotaService.tooltipText
    visible: Services.ConfigService.config.bar.enabled && Services.ConfigService.config.bar.aiQuotaEnabled
    horizontalPadding: Services.ConfigService.config.bar.moduleSpacing / 2
    configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
    configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
    configuredFontSize: Services.ConfigService.config.appearance.fontSize
    onClicked: Services.SurfaceService.toggleDashboard("ai-quota", sourceScreen, sourceSide)
    onSecondaryClicked: Services.AiQuotaService.cycleProvider()
}
