import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services" as Services
import "../modules/audio"
import "../components" as Components

PanelWindow {
    id: root

    property var controller
    property string title: controller ? controller.activeId : ""
    property real viewportWidth: width
    property real viewportHeight: height
    property bool testBarEnabled: Services.ConfigService.config.bar.enabled
    property string testBarEdge: Services.ConfigService.config.bar.edge
    property real testBarHeight: Services.ConfigService.config.bar.height
    property real contentHeightOverride: -1
    readonly property real surfaceX: surface.x
    readonly property real surfaceY: surface.y
    readonly property real surfaceWidth: surface.width
    readonly property real surfaceHeight: surface.height
    readonly property bool keyboardTargetFocused: keyTarget.activeFocus
    readonly property bool keyboardTargetRequested: keyTarget.focus
    readonly property string featureTitle: controller && controller.activeId === "audio" ? "Audio" : title

    function dismiss() { if (root.controller) root.controller.close(); }
    function dismissFromOutside() { root.dismiss(); }
    function dismissFromEscape() { root.dismiss(); }
    property Component contentComponent: null
    default property alias contentData: contentColumn.data

    visible: true
    screen: controller && typeof controller.sourceScreen === "object"
        ? controller.sourceScreen : null
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors { top: true; bottom: true; left: true; right: true }

    function availableHeight() {
        const config = Services.ConfigService.config.bar;
        const barGap = config.enabled ? config.height + 20 : 20;
        return Math.max(0, root.viewportHeight - barGap - 20);
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissFromOutside()
    }

    Rectangle {
        id: surface
        z: 1
        x: root.controller && root.controller.sourceSide === "left" ? 20
            : root.viewportWidth - width - 20
        y: root.testBarEdge === "top"
            ? (root.testBarEnabled ? root.testBarHeight + 20 : 20)
            : root.viewportHeight - height - (root.testBarEnabled
                ? root.testBarHeight + 20 : 20)
        width: Math.min(636, root.viewportWidth - 40)
        height: Math.min(root.availableHeight(),
            (root.contentHeightOverride >= 0 ? root.contentHeightOverride
                : headerRow.implicitHeight + headerRow.Layout.bottomMargin
                    + contentColumn.height) + 40)
        color: Services.ThemeService.theme.tokens.surface_sidebar
        radius: Services.ConfigService.config.appearance.radius + 2
        border.width: Services.ConfigService.config.appearance.borderWidth
        border.color: Services.ThemeService.theme.tokens.outline_variant

        MouseArea { anchors.fill: parent; onClicked: event => event.accepted = true }

        Item {
            id: keyTarget
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.dismissFromEscape()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 0

            RowLayout {
                id: headerRow
                Layout.fillWidth: true
                Layout.bottomMargin: 20
                Layout.preferredHeight: 32
                Text {
                    Layout.fillWidth: true
                    text: root.featureTitle
                    color: Services.ThemeService.theme.tokens.on_surface
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                }
                Components.IconButton {
                    id: settingsButton
                    visible: !!root.controller && root.controller.activeId === "audio"
                    iconName: "settings"
                    tooltipText: "Open pavucontrol"
                    onClicked: Services.AudioService.launchFallback()
                    ToolTip.visible: hovered
                    ToolTip.text: tooltipText
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: contentColumn.height

                ColumnLayout {
                    id: contentColumn
                    width: parent.width
                    height: loader.item ? loader.item.implicitHeight : 0
                    spacing: Services.ConfigService.config.appearance.spacing
                    Loader {
                        id: loader
                        Layout.fillWidth: true
                        Layout.preferredHeight: item ? item.implicitHeight : 0
                        active: !!root.controller && root.controller.visible
                        sourceComponent: root.contentComponent
                            || (root.controller && root.controller.activeId === "audio"
                                ? audioDashboard : unavailableDashboard)
                    }
                }
            }
        }
    }

    Component { id: audioDashboard; AudioDashboard {} }
    Component {
        id: unavailableDashboard
        Text {
            text: `${root.featureTitle || "Dashboard"} is not available yet`
            color: Services.ThemeService.theme.tokens.on_surface_variant
            font.family: Services.ConfigService.config.appearance.fontFamily
            font.pixelSize: Services.ConfigService.config.appearance.fontSize
        }
    }

    Component.onCompleted: keyTarget.forceActiveFocus()
    onClosed: root.dismiss()
}
