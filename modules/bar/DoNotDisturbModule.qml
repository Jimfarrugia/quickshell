import "../../components"
import "../../services" as Services

BarChip {
    visible: Services.ConfigService.config.bar.enabled
        && Services.NotificationService.stateReady
    icon: Services.NotificationService.dnd
        ? "do_not_disturb_on"
        : "do_not_disturb_off"
    iconColor: Services.NotificationService.dnd
        ? Services.ThemeService.theme.tokens.warning
        : Services.ThemeService.theme.tokens.secondary
    hoverText: Services.NotificationService.dnd
        ? "Do not disturb enabled"
        : "Do not disturb disabled"
    configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
    configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
    configuredFontSize: Services.ConfigService.config.appearance.fontSize
    onClicked: Services.NotificationService.setDnd(!Services.NotificationService.dnd)
}
