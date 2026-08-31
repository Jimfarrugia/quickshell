import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../services" as Services

FloatingWindow {
    id: root
    title: "QE Launcher"
    visible: true
    implicitWidth: 560
    implicitHeight: 620
    color: Services.ThemeService.theme.tokens.surface_panel
    screen: {
        const name = Services.CompositorService.focusedMonitorName;
        return Quickshell.screens.find(item => item.name === name)
            || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
    }
    function iconSource(value) {
        let icon = String(value || "").trim();
        if (icon.length > 1 && ((icon.startsWith("\"") && icon.endsWith("\""))
                || (icon.startsWith("'") && icon.endsWith("'"))))
            icon = icon.slice(1, -1);
        if (icon.startsWith("~/"))
            icon = `${Quickshell.env("HOME")}/${icon.slice(2)}`;
        if (icon.startsWith("/") || icon.startsWith("file://"))
            return icon.startsWith("/") ? `file://${icon}` : icon;
        return icon ? Quickshell.iconPath(icon, true) : "";
    }
    onVisibleChanged: if (visible) { Services.LauncherService.refresh(); query.forceActiveFocus(); }
    onClosed: Services.LauncherService.close()

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 18; spacing: 12
        TextField {
            id: query
            Layout.fillWidth: true
            placeholderText: "Search applications"
            text: Services.LauncherService.query
            onTextChanged: if (text !== Services.LauncherService.query) Services.LauncherService.setQuery(text)
            Keys.onEscapePressed: Services.LauncherService.close()
            Keys.onDownPressed: Services.LauncherService.move(1)
            Keys.onUpPressed: Services.LauncherService.move(-1)
            Keys.onEnterPressed: Services.LauncherService.launch(Services.LauncherService.selectedIndex)
            Keys.onReturnPressed: Services.LauncherService.launch(Services.LauncherService.selectedIndex)
            Keys.onPressed: event => {
                if (event.modifiers !== Qt.AltModifier) return;
                if (event.key === Qt.Key_J) Services.LauncherService.move(1);
                else if (event.key === Qt.Key_K) Services.LauncherService.move(-1);
                else if (event.key === Qt.Key_H || event.key === Qt.Key_L) event.accepted = true;
                else return;
                event.accepted = true;
            }
        }
        ListView {
            id: list
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true
            model: Services.LauncherService.results
            currentIndex: Services.LauncherService.selectedIndex
            highlightMoveDuration: 0
            highlightResizeDuration: 0
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: list.width; height: 52
                color: index === Services.LauncherService.selectedIndex ? Services.ThemeService.theme.tokens.surface_hover : "transparent"
                Item {
                    id: iconSlot
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32

                    IconImage {
                        id: applicationIcon
                        anchors.fill: parent
                        source: root.iconSource(modelData.icon)
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.fill: parent
                        visible: !applicationIcon.visible
                        text: "package_2"
                        color: Services.ThemeService.theme.tokens.on_surface_disabled
                        font.family: Services.ConfigService.config.appearance.iconFontFamily
                        font.pixelSize: 26
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                Text {
                    anchors.left: iconSlot.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                    color: Services.ThemeService.theme.tokens.on_surface_panel
                }
                MouseArea { anchors.fill: parent; onClicked: Services.LauncherService.selectedIndex = index; onDoubleClicked: Services.LauncherService.launch(index) }
            }
        }
        Text { visible: Services.LauncherService.lastFailure !== ""; text: Services.LauncherService.lastFailure; color: Services.ThemeService.theme.tokens.error; wrapMode: Text.Wrap; Layout.fillWidth: true }
        Button { visible: Services.LauncherService.lastFailure !== ""; text: "Retry"; onClicked: Services.LauncherService.launch(Services.LauncherService.selectedIndex) }
    }
}
