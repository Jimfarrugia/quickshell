import QtQuick
import "../../components"
import "../../services" as Services
import "../../utils/AiQuota.mjs" as AiQuota

BarChip {
    property var sourceScreen: null
    property var dashboardController
    property string sourceSide: "left"
    readonly property var selected: Services.AiQuotaService.provider(Services.AiQuotaService.selectedProvider)
    readonly property bool current: selected.weekly.status === "ok"
    property bool registered: false

    function updateConsumer() {
        const shouldRegister = visible;
        if (shouldRegister && !registered) {
            Services.AiQuotaService.registerConsumer();
            registered = true;
        } else if (!shouldRegister && registered) {
            Services.AiQuotaService.unregisterConsumer();
            registered = false;
        }
    }

    text: current ? `${AiQuota.formatPercent(selected.weekly.remainingPercent)}%` : "--"
    icon: "robot_2"
    iconColor: current ? Services.ThemeService.theme.tokens.secondary : Services.ThemeService.theme.tokens.error
    textColor: current ? Services.ThemeService.theme.tokens.on_surface_disabled : Services.ThemeService.theme.tokens.error
    warning: selected.freshness === "stale"
    hoverText: Services.AiQuotaService.tooltipText
    visible: Services.ConfigService.config.bar.enabled && Services.ConfigService.config.bar.aiQuotaEnabled
    horizontalPadding: Services.ConfigService.config.bar.moduleSpacing / 2
    configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
    configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
    configuredFontSize: Services.ConfigService.config.appearance.fontSize
    onClicked: if (dashboardController) dashboardController.toggle("ai-quota", sourceScreen, sourceSide)
    onSecondaryClicked: Services.AiQuotaService.cycleProvider()
    onVisibleChanged: updateConsumer()
    Component.onCompleted: updateConsumer()
    Component.onDestruction: if (registered) Services.AiQuotaService.unregisterConsumer()
}
