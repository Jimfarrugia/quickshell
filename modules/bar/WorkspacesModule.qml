import QtQuick
import "../../components"
import "../../services" as Services

Row {
    spacing: 0

    Repeater {
        model: Services.CompositorService.workspaceModel
        delegate: BarChip {
            required property var modelData
            visible: modelData.id > 0
            icon: modelData.focused ? "adjust" : "circle"
            warning: modelData.urgent
            iconColor: modelData.focused ? Services.ThemeService.theme.tokens.secondary
                                         : Services.ThemeService.theme.tokens.on_surface_disabled
            backgroundColor: "transparent"
            horizontalPadding: Services.ConfigService.config.bar.moduleSpacing * 3 / 8
            configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
            configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
            configuredFontSize: Services.ConfigService.config.appearance.fontSize
            onClicked: Services.CompositorService.activateWorkspace(modelData)
        }
    }
}
