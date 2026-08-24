import QtQuick
import Quickshell
import "../../components"
import "../../services" as Services

FloatingWindow {
    id: root
    visible: Services.ConfigService.config.preview.enabled
    title: "QE Phase 1 Theme Preview"
    implicitWidth: 360
    implicitHeight: 220
    color: "transparent"

    ThemePreview {
        anchors.fill: parent
        configuredRadius: Services.ConfigService.config.appearance.radius
        configuredBorderWidth: Services.ConfigService.config.appearance.borderWidth
        configuredSpacing: Services.ConfigService.config.appearance.spacing
        configuredFontFamily: Services.ConfigService.config.appearance.fontFamily
    }
}
