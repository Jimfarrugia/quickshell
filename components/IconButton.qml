import QtQuick
import "../services" as Services
import "." as Components

Rectangle {
    id: root

    property string iconName: ""
    property real iconSize: 24
    property bool toggleable: false
    property bool checked: false
    property color toggleColor: Services.ThemeService.theme.tokens.success
    property color foregroundColor: Services.ThemeService.theme.tokens.on_surface
    property color borderColor: Services.ThemeService.theme.tokens.outline
    property string tooltipText: ""
    property bool tooltipBelow: false
    readonly property bool hovered: hover.hovered
    signal clicked()
    signal toggled(bool checked)

    implicitWidth: 36
    implicitHeight: 36
    radius: 6
    border.width: 1
    border.color: root.toggleable && root.checked ? root.toggleColor : root.borderColor
    color: tap.pressed
        ? Services.ThemeService.theme.tokens.surface_pressed
        : (hover.hovered ? Services.ThemeService.theme.tokens.surface
            : Services.ThemeService.theme.tokens.background)

    Text {
        anchors.centerIn: parent
        text: root.iconName
        color: root.toggleable && root.checked
            ? root.toggleColor : root.foregroundColor
        font.family: Services.ConfigService.config.appearance.iconFontFamily
        font.pixelSize: root.iconSize
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    Components.BarTooltip {
        anchorItem: root
        text: root.tooltipText
        below: root.tooltipBelow
        show: hover.hovered && root.tooltipText.length > 0
    }

    TapHandler {
        id: tap
        onTapped: root.toggleable ? root.toggled(!root.checked) : root.clicked()
    }

}
