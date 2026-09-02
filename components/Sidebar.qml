import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services" as Services

PanelWindow {
    id: root

    property real contentWidth: 384
    property real outerMargin: 20
    property bool avoidBottomBar: true
    property bool dismissOnOutsideClick: false
    signal outsideClicked()
    property color backgroundColor: Services.ThemeService.theme.tokens.surface_sidebar
    property real cornerRadius: Services.ConfigService.config.appearance.radius + 2
    default property alias contentData: content.data

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    visible: true
    implicitWidth: root.dismissOnOutsideClick
        ? (Quickshell.screens.length > 0 ? Quickshell.screens[0].width : 0)
        : root.contentWidth + root.outerMargin * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    WlrLayershell.layer: WlrLayer.Overlay
    anchors {
        top: true
        bottom: true
        right: true
        left: root.dismissOnOutsideClick ? true : undefined
    }
    margins {
        top: root.dismissOnOutsideClick ? 0 : root.outerMargin
        right: root.dismissOnOutsideClick ? 0 : root.outerMargin
        bottom: root.dismissOnOutsideClick ? 0 : root.outerMargin + (root.avoidBottomBar
            && Services.ConfigService.config.bar.enabled
            && Services.ConfigService.config.bar.edge === "bottom"
            ? Services.ConfigService.config.bar.height : 0)
    }

    Rectangle {
        id: sidebarSurface
        z: 1
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: root.contentWidth + root.outerMargin * 2
        anchors.margins: root.dismissOnOutsideClick ? root.outerMargin : 0
        color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 245 / 255)
        radius: root.cornerRadius
        border.width: Services.ConfigService.config.appearance.borderWidth
        border.color: Services.ThemeService.theme.tokens.outline_variant

        MouseArea {
            anchors.fill: parent
            onClicked: event => event.accepted = true
        }
    }

    MouseArea {
        z: 0
        anchors.fill: parent
        enabled: root.dismissOnOutsideClick
        onClicked: root.outsideClicked()
    }

    Item {
        id: content
        z: 2
        anchors.fill: sidebarSurface
    }
}
