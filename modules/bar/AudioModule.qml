import "../../components"
import "../../services" as Services

BarChip {
    function iconForVolume(volumePercent) {
        if (volumePercent <= 30) return "volume_mute";
        if (volumePercent <= 60) return "volume_down";
        return "volume_up";
    }

    visible: Services.AudioService.availability !== "unavailable"
    icon: Services.AudioService.muted ? "volume_off" : iconForVolume(Services.AudioService.volumePercent)
    iconColor: Services.AudioService.muted ? Services.ThemeService.theme.tokens.error
                                           : Services.ThemeService.theme.tokens.accentSecondary
    text: Services.AudioService.availability === "available"
        ? (Services.AudioService.muted ? "" : `${Services.AudioService.volumePercent}%`)
        : "Audio..."
    warning: Services.AudioService.availability !== "available"
    configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
    configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
    configuredFontSize: Services.ConfigService.config.appearance.fontSize
}
