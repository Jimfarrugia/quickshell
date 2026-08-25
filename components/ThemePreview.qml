import QtQuick
import "../services" as Services

Rectangle {
    id: root
    property real configuredRadius: 10
    property real configuredBorderWidth: 1
    property real configuredSpacing: 8
    property string configuredFontFamily: "sans-serif"

    color: Services.ThemeService.theme.tokens.background
    radius: configuredRadius
    border.width: configuredBorderWidth
    border.color: Services.ThemeService.theme.tokens.outline

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: root.configuredSpacing

        Text {
            text: `QE Theme: ${Services.ThemeService.theme.name}`
            color: Services.ThemeService.theme.tokens.on_background
            font.family: root.configuredFontFamily
            font.pixelSize: 20
            font.bold: true
        }
        Text {
            text: Services.ThemeService.operation === "pending" ? "Saving requested theme..." : "Phase 1 preview"
            color: Services.ThemeService.theme.tokens.on_surface_variant
        }
        Row {
            spacing: 8
            Repeater {
                model: Services.ThemeService.catalog
                delegate: Rectangle {
                    required property var modelData
                    width: 130
                    height: 42
                    radius: 6
                    color: modelData.id === Services.ThemeService.activeThemeId
                        ? Services.ThemeService.theme.tokens.primary_container
                        : (selectorArea.pressed
                            ? Services.ThemeService.theme.tokens.surface_pressed
                            : (selectorHover.hovered
                                ? Services.ThemeService.theme.tokens.surface_hover
                                : Services.ThemeService.theme.tokens.surface))
                    border.color: Services.ThemeService.theme.tokens.outline
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.name
                        color: modelData.id === Services.ThemeService.activeThemeId
                            ? Services.ThemeService.theme.tokens.on_primary_container
                            : Services.ThemeService.theme.tokens.on_surface
                    }
                    HoverHandler { id: selectorHover }
                    MouseArea {
                        id: selectorArea
                        anchors.fill: parent
                        enabled: Services.ThemeService.operation !== "pending"
                        onClicked: Services.ThemeService.requestTheme(modelData.id)
                    }
                }
            }
        }
        Row {
            spacing: 8
            Repeater {
                model: ["success", "warning", "error", "primary"]
                delegate: Rectangle {
                    required property string modelData
                    width: 58
                    height: 24
                    radius: 4
                    color: Services.ThemeService.theme.tokens[modelData]
                }
            }
        }
    }
}
