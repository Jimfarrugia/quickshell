import QtQuick
import "../../services" as Services

Text {
    text: Services.CompositorService.focusedWindowTitle
    color: Services.ThemeService.theme.tokens.on_surface_variant
    font.family: Services.ConfigService.config.appearance.fontFamily
    font.pixelSize: Services.ConfigService.config.appearance.fontSize
    elide: Text.ElideRight
    maximumLineCount: 1
}
