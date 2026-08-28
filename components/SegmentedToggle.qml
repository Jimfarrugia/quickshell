import QtQuick
import QtQuick.Layouts
import "../services" as Services

Rectangle {
    id: root

    property var labels: ["First", "Second"]
    property bool checked: false
    signal toggled()

    function activate() {
        root.forceActiveFocus();
        root.toggled();
    }

    activeFocusOnTab: true
    implicitHeight: 38
    radius: Services.ConfigService.config.appearance.radius
    color: Services.ThemeService.theme.tokens.surface
    clip: true

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Repeater {
            id: optionRepeater
            model: 2
            delegate: Item {
                id: optionRoot
                required property int index
                objectName: `segment-${index}`
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.fill: parent
                    radius: Services.ConfigService.config.appearance.radius
                    color: optionRoot.index === (root.checked ? 1 : 0)
                        ? Services.ThemeService.theme.tokens.primary
                        : Services.ThemeService.theme.tokens.surface_variant
                }

                Rectangle {
                    visible: optionRoot.index === 0
                    anchors.right: parent.right
                    width: Services.ConfigService.config.appearance.radius
                    height: parent.height
                    color: optionRoot.index === (root.checked ? 1 : 0)
                        ? Services.ThemeService.theme.tokens.primary
                        : Services.ThemeService.theme.tokens.surface_variant
                }

                Rectangle {
                    visible: optionRoot.index === 1
                    anchors.left: parent.left
                    width: Services.ConfigService.config.appearance.radius
                    height: parent.height
                    color: optionRoot.index === (root.checked ? 1 : 0)
                        ? Services.ThemeService.theme.tokens.primary
                        : Services.ThemeService.theme.tokens.surface_variant
                }

                Text {
                    anchors.centerIn: parent
                    text: root.labels[optionRoot.index] || ""
                    color: optionRoot.index === (root.checked ? 1 : 0)
                        ? Services.ThemeService.theme.tokens.on_primary
                        : Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.weight: Font.DemiBold
                }

                TapHandler {
                    onTapped: root.activate()
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        z: 1
        radius: Services.ConfigService.config.appearance.radius
        color: "transparent"
        border.width: root.activeFocus ? 2 : 0
        border.color: Services.ThemeService.theme.tokens.focus_ring
    }
}
