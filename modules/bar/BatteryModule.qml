import QtQuick
import "../../components"
import "../../services" as Services

BarChip {
    id: root

    readonly property bool critical: Services.PowerService.percentage <= 15
    readonly property bool low: Services.PowerService.percentage >= 16
                                && Services.PowerService.percentage <= 24
    readonly property color stateColor: critical ? Services.ThemeService.theme.tokens.error
                                                 : (low ? Services.ThemeService.theme.tokens.warning
                                                          : Services.ThemeService.theme.tokens.on_surface_disabled)

    function iconForPercentage(percentage) {
        if (percentage <= 15) return "battery_android_alert";
        if (percentage <= 24) return "battery_android_frame_1";
        if (percentage <= 34) return "battery_android_frame_2";
        if (percentage <= 49) return "battery_android_frame_3";
        if (percentage <= 64) return "battery_android_frame_4";
        if (percentage <= 80) return "battery_android_frame_5";
        if (percentage <= 95) return "battery_android_frame_6";
        return "battery_android_frame_full";
    }

    visible: Services.PowerService.availability !== "unavailable"
    icon: Services.PowerService.charging
        ? "battery_android_frame_bolt"
        : iconForPercentage(Services.PowerService.percentage)
    iconColor: Services.PowerService.charging
        ? Services.ThemeService.theme.tokens.charging
        : (critical || low ? stateColor : Services.ThemeService.theme.tokens.secondary)
    text: Services.PowerService.availability === "available"
        ? `${Services.PowerService.percentage}%`
        : "Battery..."
    textColor: Services.PowerService.charging
        ? Services.ThemeService.theme.tokens.on_surface_disabled
        : (critical || low ? stateColor : Services.ThemeService.theme.tokens.on_surface_disabled)
    warning: false
    hoverText: Services.PowerService.availability === "available"
        ? Services.PowerService.remainingTimeText : "Battery unavailable"
    configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
    configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
    configuredFontSize: Services.ConfigService.config.appearance.fontSize
}
