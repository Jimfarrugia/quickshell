import QtQuick
import "../services" as Services

Rectangle {
    id: root
    property real configuredRadius: 10
    property real configuredBorderWidth: 1
    property real configuredSpacing: 8
    property string configuredFontFamily: "sans-serif"

    color: Services.ThemeService.theme.tokens.surfaceBase
    radius: configuredRadius
    border.width: configuredBorderWidth
    border.color: Services.ThemeService.theme.tokens.border

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: root.configuredSpacing

        Text {
            text: `QE Theme: ${Services.ThemeService.theme.name}`
            color: Services.ThemeService.theme.tokens.textPrimary
            font.family: root.configuredFontFamily
            font.pixelSize: 20
            font.bold: true
        }
        Text {
            text: Services.ThemeService.operation === "pending" ? "Saving requested theme..." : "Phase 1 preview"
            color: Services.ThemeService.theme.tokens.textSecondary
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
                        ? Services.ThemeService.theme.tokens.accentPrimary
                        : Services.ThemeService.theme.tokens.surfaceRaised
                    border.color: Services.ThemeService.theme.tokens.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.name
                        color: modelData.id === Services.ThemeService.activeThemeId
                            ? Services.ThemeService.theme.tokens.surfaceBase
                            : Services.ThemeService.theme.tokens.textPrimary
                    }
                    MouseArea {
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
                model: ["success", "warning", "error", "accentPrimary"]
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
