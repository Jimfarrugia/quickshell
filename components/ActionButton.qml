import QtQuick
import QtQuick.Controls.Basic
import "../services" as Services

AbstractButton {
    id: root

    property string iconName: ""
    property real iconSize: 24
    property string tone: "neutral"
    property string emphasis: "outlined"
    property bool pending: false
    property real radius: Services.ConfigService.config.appearance.radius
    property real borderWidth: Services.ConfigService.config.appearance.borderWidth
    readonly property bool selected: root.checkable && root.checked
    readonly property color resolvedForegroundColor: {
        if (root.pending) return Services.ThemeService.theme.tokens.on_primary;
        if (!root.enabled) return Services.ThemeService.theme.tokens.on_surface_disabled;
        if (root.selected) return Services.ThemeService.theme.tokens.on_primary_container;
        if (root.tone === "primary" && root.emphasis === "filled")
            return Services.ThemeService.theme.tokens.on_primary;
        if (root.hovered || root.pressed) return Services.ThemeService.theme.tokens.on_surface;
        if (root.tone === "primary") return root.emphasis === "ghost"
            ? Services.ThemeService.theme.tokens.primary
            : Services.ThemeService.theme.tokens.on_surface;
        if (root.tone === "destructive") return root.emphasis === "ghost"
            ? Services.ThemeService.theme.tokens.error
            : Services.ThemeService.theme.tokens.on_surface;
        return Services.ThemeService.theme.tokens.on_surface_subdued;
    }
    readonly property color resolvedBackgroundColor: {
        if (root.pending) return Services.ThemeService.theme.tokens.primary;
        if (!root.enabled) return Services.ThemeService.theme.tokens.surface;
        if (root.selected) return Services.ThemeService.theme.tokens.primary_container;
        if (root.tone === "primary" && root.emphasis === "filled")
            return Services.ThemeService.theme.tokens.primary;
        if (root.pressed) return Services.ThemeService.theme.tokens.surface_pressed;
        if (root.hovered) return Services.ThemeService.theme.tokens.surface_hover;
        return root.emphasis === "ghost" ? "transparent" : Services.ThemeService.theme.tokens.background;
    }
    readonly property color resolvedBorderColor: {
        if (root.activeFocus) return Services.ThemeService.theme.tokens.focus_ring;
        if (root.pending) return Services.ThemeService.theme.tokens.primary;
        if (!root.enabled) return Services.ThemeService.theme.tokens.outline_variant;
        if (root.selected || root.tone === "primary")
            return Services.ThemeService.theme.tokens.primary;
        if (root.tone === "destructive") return Services.ThemeService.theme.tokens.error;
        return Services.ThemeService.theme.tokens.outline_variant;
    }
    readonly property real resolvedBorderWidth: root.activeFocus
        ? Math.max(2, root.borderWidth)
        : (root.emphasis === "ghost" ? 0 : root.borderWidth)

    hoverEnabled: true
    activeFocusOnTab: true
    implicitWidth: root.text.length > 0 ? Math.max(36, contentRow.implicitWidth + 24) : 36
    implicitHeight: 36

    background: Rectangle {
        radius: root.radius
        color: root.resolvedBackgroundColor
        border.width: root.resolvedBorderWidth
        border.color: root.resolvedBorderColor
    }

    contentItem: Item {
        implicitWidth: contentRow.implicitWidth
        implicitHeight: contentRow.implicitHeight

        Row {
            id: contentRow
            objectName: "action-content"
            anchors.centerIn: parent
            spacing: root.iconName.length > 0 && root.text.length > 0 ? 8 : 0

            Text {
                objectName: "action-icon"
                visible: root.iconName.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: root.iconName
                color: root.resolvedForegroundColor
                font.family: Services.ConfigService.config.appearance.iconFontFamily
                font.pixelSize: root.iconSize
            }

            Text {
                visible: root.text.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: root.text
                color: root.resolvedForegroundColor
                font.family: Services.ConfigService.config.appearance.fontFamily
                font.pixelSize: Services.ConfigService.config.appearance.fontSize
                font.weight: Font.DemiBold
            }
        }
    }
}
