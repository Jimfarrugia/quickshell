import QtQuick
import QtQuick.Layouts
import "../../services" as Services

Item {
    id: root

    required property var record
    property real contentWidth: 360
    implicitWidth: contentWidth
    implicitHeight: card.implicitHeight

    Rectangle {
        id: card
        width: root.width
        implicitHeight: content.implicitHeight + 24
        radius: Services.ConfigService.config.appearance.radius
        color: Services.ThemeService.theme.tokens.surface_tooltip
        border.width: 1
        border.color: root.record.data.urgency === "critical"
            ? Services.ThemeService.theme.tokens.error : Services.ThemeService.theme.tokens.outline

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.record.data.appName
                    color: Services.ThemeService.theme.tokens.on_surface_tooltip
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Text {
                    text: root.record.data.urgency.toUpperCase()
                    color: root.record.data.urgency === "critical"
                        ? Services.ThemeService.theme.tokens.error : Services.ThemeService.theme.tokens.on_surface_placeholder
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 5
                    color: closeHover.hovered ? Services.ThemeService.theme.tokens.surface_hover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        color: Services.ThemeService.theme.tokens.on_surface_tooltip
                        font.family: Services.ConfigService.config.appearance.iconFontFamily
                        font.pixelSize: 16
                    }
                    HoverHandler { id: closeHover }
                    TapHandler { onTapped: Services.NotificationService.dismiss(root.record.data.id) }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.record.data.summary
                color: Services.ThemeService.theme.tokens.on_surface_tooltip
                font.family: Services.ConfigService.config.appearance.fontFamily
                font.pixelSize: 15
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.record.data.body
                textFormat: Text.RichText
                color: Services.ThemeService.theme.tokens.on_surface_placeholder
                font.family: Services.ConfigService.config.appearance.fontFamily
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                maximumLineCount: 8
                elide: Text.ElideRight
            }

            Image {
                Layout.alignment: Qt.AlignHCenter
                visible: root.record.data.image.length > 0
                source: root.record.data.image
                sourceSize.width: 96
                sourceSize.height: 96
                width: Math.min(96, implicitWidth)
                height: Math.min(96, implicitHeight)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
            }

            Rectangle {
                Layout.fillWidth: true
                visible: root.record.data.hasProgress
                implicitHeight: 6
                radius: 3
                color: Services.ThemeService.theme.tokens.surface_variant

                Rectangle {
                    width: parent.width * root.record.data.progress / 100
                    height: parent.height
                    radius: parent.radius
                    color: Services.ThemeService.theme.tokens.primary
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: actionRepeater.count > 0

                Repeater {
                    id: actionRepeater
                    model: root.record.data.actions
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 5
                        color: actionHover.hovered ? Services.ThemeService.theme.tokens.surface_hover : Services.ThemeService.theme.tokens.surface_variant

                        Text {
                            anchors.centerIn: parent
                            text: modelData.text
                            color: Services.ThemeService.theme.tokens.on_surface_variant
                            font.family: Services.ConfigService.config.appearance.fontFamily
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        HoverHandler { id: actionHover }
                        TapHandler {
                            onTapped: Services.NotificationService.invokeAction(root.record.data.id, modelData.identifier)
                        }
                    }
                }
            }
        }
    }
}
