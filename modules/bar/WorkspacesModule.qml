import QtQuick
import "../../components"
import "../../services" as Services

Row {
    id: root
    spacing: 0

    property var sourceScreen: null

    function itemAt(index) {
        return workspaceRepeater.itemAt(index);
    }

    Repeater {
        id: workspaceRepeater
        model: Services.CompositorService.workspaceModel
        delegate: BarChip {
            required property var modelData
            visible: Services.CompositorService.workspaceVisibleOnScreen(modelData, root.sourceScreen)
            icon: modelData.focused ? "adjust" : "circle"
            warning: !!modelData.urgent
            iconColor: modelData.urgent ? Services.ThemeService.theme.tokens.warning
                : Services.ThemeService.theme.tokens.on_surface_indicator
            backgroundColor: "transparent"
            horizontalPadding: Services.ConfigService.config.bar.moduleSpacing * 3 / 8
            configuredFontFamily: Services.ConfigService.config.appearance.monospaceFontFamily
            configuredIconFontFamily: Services.ConfigService.config.appearance.iconFontFamily
            configuredFontSize: Services.ConfigService.config.appearance.fontSize
            onClicked: Services.CompositorService.activateWorkspace(modelData)
        }
    }
}
