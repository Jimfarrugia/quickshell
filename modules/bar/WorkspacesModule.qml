import QtQuick
import "../../components"
import "../../services" as Services

Row {
    id: root
    spacing: 0

    property var sourceScreen: null

    Repeater {
        model: Services.CompositorService.workspaceModel
        delegate: BarChip {
            required property var modelData
            visible: Services.CompositorService.workspaceVisibleOnScreen(modelData, root.sourceScreen)
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
