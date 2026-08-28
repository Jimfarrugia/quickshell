import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components" as Components
import "../../services" as Services

FloatingWindow {
    id: root

    title: "QE Notifications"
    visible: true
    implicitWidth: 480
    implicitHeight: 620
    color: "transparent"
    onClosed: Services.SurfaceService.closeNotificationCenter()

    Rectangle {
        anchors.fill: parent
        color: Services.ThemeService.theme.tokens.surface_panel

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        text: "QE NOTIFICATIONS"
                        color: Services.ThemeService.theme.tokens.secondary
                        font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.5
                    }
                    Text {
                        text: "Current session"
                        color: Services.ThemeService.theme.tokens.on_surface_panel
                        font.family: Services.ConfigService.config.appearance.fontFamily
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    implicitWidth: 70
                    implicitHeight: 32
                    radius: 6
                    color: clearHover.hovered ? Services.ThemeService.theme.tokens.surface_hover : Services.ThemeService.theme.tokens.surface_variant
                    Text {
                        anchors.centerIn: parent
                        text: "Clear"
                        color: Services.ThemeService.theme.tokens.on_surface_variant
                        font.family: Services.ConfigService.config.appearance.fontFamily
                        font.pixelSize: 12
                    }
                    HoverHandler { id: clearHover }
                    TapHandler { onTapped: Services.NotificationService.clearHistory() }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: Services.NotificationService.ready
                        ? `${Services.NotificationService.history.length} notifications`
                        : `Unavailable: ${Services.NotificationService.owner}`
                    color: Services.NotificationService.ready
                        ? Services.ThemeService.theme.tokens.on_surface_variant
                        : Services.ThemeService.theme.tokens.error
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 11
                }
                Components.SegmentedToggle {
                    id: dndToggle
                    labels: ["DND off", "DND on"]
                    checked: Services.NotificationService.dnd
                    implicitWidth: 150
                    implicitHeight: 32
                    onToggled: Services.NotificationService.setDnd(!Services.NotificationService.dnd)
                }
            }

            ListView {
                id: historyList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: Services.NotificationService.history

                delegate: Rectangle {
                    required property var modelData
                    width: historyList.width
                    implicitHeight: historyContent.implicitHeight + 20
                    radius: Services.ConfigService.config.appearance.radius
                    color: Services.ThemeService.theme.tokens.surface
                    border.width: 1
                    border.color: modelData.data.urgency === "critical"
                        ? Services.ThemeService.theme.tokens.error : Services.ThemeService.theme.tokens.outline_variant

                    ColumnLayout {
                        id: historyContent
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4
                        Text {
                            Layout.fillWidth: true
                            text: `${modelData.data.appName}  /  ${modelData.data.urgency}`
                            color: Services.ThemeService.theme.tokens.on_surface_variant
                            font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                            font.pixelSize: 10
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.data.summary
                            color: Services.ThemeService.theme.tokens.on_surface
                            font.family: Services.ConfigService.config.appearance.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: modelData.data.body
                            textFormat: Text.RichText
                            color: Services.ThemeService.theme.tokens.on_surface_variant
                            font.family: Services.ConfigService.config.appearance.fontFamily
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: historyList.count === 0
                    text: "No notifications in this session"
                    color: Services.ThemeService.theme.tokens.on_surface_placeholder
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 14
                }
            }
        }
    }
}
