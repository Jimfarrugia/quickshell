import "../../components"
import "../../services" as Services

BarChip {
    visible: Services.ConfigService.config.bar.enabled
        && Services.ConfigService.config.bar.idleInhibitorEnabled
        && Services.IdleService.availability === "available"
    icon: Services.IdleService.requested ? "visibility" : "visibility_off"
    iconColor: Services.IdleService.requested
        ? Services.ThemeService.theme.tokens.success
        : Services.ThemeService.theme.tokens.accentSecondary
    hoverText: Services.IdleService.requested ? "Requested" : "Disabled"
    configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
    configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
    configuredFontSize: Services.ConfigService.config.appearance.fontSize
    onClicked: Services.IdleService.toggle()
}
