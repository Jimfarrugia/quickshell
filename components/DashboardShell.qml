import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services" as Services

PanelWindow {
    id: root

    property var controller
    property string title: controller ? controller.activeId : ""
    property Component contentComponent: null
    default property alias contentData: contentColumn.data

    visible: true
    screen: controller ? controller.sourceScreen : null
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
        return Math.max(0, height - barGap - 20);
    }

    MouseArea {
        anchors.fill: parent
        onClicked: if (root.controller) root.controller.close()
    }

    Rectangle {
        id: surface
        z: 1
        x: root.controller && root.controller.sourceSide === "left" ? 20
            : parent.width - width - 20
        y: Services.ConfigService.config.bar.edge === "top"
            ? (Services.ConfigService.config.bar.enabled
                ? Services.ConfigService.config.bar.height + 20 : 20)
            : parent.height - height - (Services.ConfigService.config.bar.enabled
                ? Services.ConfigService.config.bar.height + 20 : 20)
        width: Math.min(636, parent.width - 40)
        height: Math.min(root.availableHeight(), contentColumn.implicitHeight + 40)
        color: Services.ThemeService.theme.tokens.surface_sidebar
        radius: Services.ConfigService.config.appearance.radius + 2
        border.width: Services.ConfigService.config.appearance.borderWidth
        border.color: Services.ThemeService.theme.tokens.outline_variant

        MouseArea { anchors.fill: parent; onClicked: event => event.accepted = true }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: Services.ConfigService.config.appearance.spacing

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Services.ThemeService.theme.tokens.on_surface
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: contentColumn.implicitHeight

                ColumnLayout {
                    id: contentColumn
                    width: parent.width
                    spacing: Services.ConfigService.config.appearance.spacing
                    Loader { active: root.contentComponent !== null; sourceComponent: root.contentComponent }
                }
            }
        }
    }

    Keys.onEscapePressed: if (root.controller) root.controller.close()
    Component.onCompleted: forceActiveFocus()
    onClosed: if (root.controller) root.controller.close()
}
