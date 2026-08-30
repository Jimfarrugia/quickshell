import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services" as Services

PanelWindow {
    id: root

    property real contentWidth: 384
    property real outerMargin: 20
    property bool avoidBottomBar: true
    property color backgroundColor: Services.ThemeService.theme.tokens.surface_sidebar
    property real cornerRadius: Services.ConfigService.config.appearance.radius + 2
    default property alias contentData: content.data

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    visible: true
    implicitWidth: root.contentWidth + root.outerMargin * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    WlrLayershell.layer: WlrLayer.Overlay
    anchors {
        top: true
        bottom: true
        right: true
    }
    margins {
        top: root.outerMargin
        right: root.outerMargin
        bottom: root.outerMargin + (root.avoidBottomBar
            && Services.ConfigService.config.bar.enabled
            && Services.ConfigService.config.bar.edge === "bottom"
            ? Services.ConfigService.config.bar.height : 0)
    }

    Rectangle {
        id: sidebarSurface
        anchors.fill: parent
        color: root.backgroundColor
        radius: root.cornerRadius
        border.width: Services.ConfigService.config.appearance.borderWidth
        border.color: Services.ThemeService.theme.tokens.outline_variant
    }

    Item {
        id: content
        anchors.fill: parent
    }
}
