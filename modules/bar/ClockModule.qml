import "../../components"
import "../../services" as Services

BarChip {
    text: Services.TimeService.dateText
    trailingText: Services.TimeService.timeText
    trailingTextColor: Services.ThemeService.theme.tokens.primary
    horizontalPadding: Services.ConfigService.config.bar.moduleSpacing / 2
    contentSpacing: Services.ConfigService.config.bar.moduleSpacing * 2
    configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
    configuredFontSize: Services.ConfigService.config.appearance.fontSize
}
