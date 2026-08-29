import QtQuick
import QtQuick.Layouts
import "../../services" as Services

Item {
    id: root
    property var item: null
    implicitWidth: 330
    implicitHeight: card.implicitHeight

    Rectangle {
        id: card
        width: root.width
        implicitHeight: content.implicitHeight + 24
        radius: Services.ConfigService.config.appearance.radius
        color: Services.ThemeService.theme.tokens.surface_tooltip
        border.width: 1
        border.color: root.item && root.item.state === "failed" ? Services.ThemeService.theme.tokens.error : Services.ThemeService.theme.tokens.outline

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 12
            spacing: 7

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.item ? root.item.icon : "info"
                    color: root.item && root.item.state === "failed" ? Services.ThemeService.theme.tokens.error : Services.ThemeService.theme.tokens.secondary
                    font.family: Services.ConfigService.config.appearance.iconFontFamily
                    font.pixelSize: 19
                }
                Text {
                    Layout.fillWidth: true
                    text: root.item ? root.item.title : "QE"
                    color: Services.ThemeService.theme.tokens.on_surface_tooltip
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
                Text {
                    text: root.item && root.item.state === "pending" ? "PENDING" : (root.item && root.item.state === "failed" ? "FAILED" : "")
                    color: root.item && root.item.state === "failed" ? Services.ThemeService.theme.tokens.error : Services.ThemeService.theme.tokens.primary
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 9
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.item ? root.item.detail : ""
                color: Services.ThemeService.theme.tokens.on_surface_placeholder
                font.family: Services.ConfigService.config.appearance.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                visible: root.item && root.item.value >= 0
                implicitHeight: 5
                radius: 3
                color: Services.ThemeService.theme.tokens.surface_variant
                Rectangle {
                    width: root.item ? parent.width * Math.min(100, root.item.value) / 100 : 0
                    height: parent.height
                    radius: parent.radius
                    color: root.item && root.item.state === "failed" ? Services.ThemeService.theme.tokens.error : Services.ThemeService.theme.tokens.primary
                }
            }
        }
    }
}
