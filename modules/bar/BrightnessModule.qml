import QtQuick
import "../../components"
import "../../services" as Services

BarChip {
    id: root

    readonly property bool stale: Services.BrightnessService.freshness === "stale"
    readonly property bool unavailable: Services.BrightnessService.availability !== "available"
    readonly property bool pending: Services.BrightnessService.operation === "pending"
        && Services.BrightnessService.pendingPercent >= 0
    readonly property int displayPercent: pending
        ? Services.BrightnessService.pendingPercent
        : Services.BrightnessService.confirmedPercent

    function iconForPercentage(percentage) {
        if (percentage < 30) return "brightness_low";
        if (percentage <= 70) return "brightness_medium";
        return "brightness_high";
    }

    visible: Services.ConfigService.config.bar.enabled
        && Services.ConfigService.config.bar.brightnessEnabled
        && Services.BrightnessService.availability !== "unavailable"
    icon: iconForPercentage(displayPercent)
    iconColor: unavailable
        ? Services.ThemeService.theme.tokens.on_surface_disabled
        : (Services.BrightnessService.operation === "failed" ? Services.ThemeService.theme.tokens.error
            : (stale ? Services.ThemeService.theme.tokens.warning
            : (pending ? Services.ThemeService.theme.tokens.primary
                : Services.ThemeService.theme.tokens.on_surface_indicator)))
    text: unavailable
        ? "Light..."
        : `${displayPercent}%`
     textColor: unavailable ? Services.ThemeService.theme.tokens.on_surface_disabled
         : (Services.BrightnessService.operation === "failed" ? Services.ThemeService.theme.tokens.error
             : (stale ? Services.ThemeService.theme.tokens.warning
             : (pending ? Services.ThemeService.theme.tokens.primary
                 : Services.ThemeService.theme.tokens.on_surface_subdued)))
    configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
    configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
    configuredFontSize: Services.ConfigService.config.appearance.fontSize

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            Services.BrightnessService.wheelStep(event.angleDelta.y);
            event.accepted = true;
        }
    }
}
