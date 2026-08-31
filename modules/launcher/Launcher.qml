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
    color: "transparent"
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

    Rectangle {
        id: surface
        anchors.fill: parent
        color: Services.ThemeService.theme.tokens.surface_panel
        radius: Services.ConfigService.config.appearance.radius + 2
        border.width: Services.ConfigService.config.appearance.borderWidth
        border.color: Services.ThemeService.theme.tokens.outline_variant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: Services.ConfigService.config.appearance.spacing

        TextField {
            id: query
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            placeholderText: "Search applications..."
            text: Services.LauncherService.query
            color: Services.ThemeService.theme.tokens.on_surface
            selectionColor: Services.ThemeService.theme.tokens.primary
            selectedTextColor: Services.ThemeService.theme.tokens.on_primary
            font.family: Services.ConfigService.config.appearance.fontFamily
            font.pixelSize: 16
            leftPadding: 48
            rightPadding: 16
            topPadding: 2
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

            background: Rectangle {
                radius: Services.ConfigService.config.appearance.radius
                color: query.activeFocus
                    ? Services.ThemeService.theme.tokens.surface_variant
                    : Services.ThemeService.theme.tokens.surface
                border.width: query.activeFocus
                    ? Math.max(2, Services.ConfigService.config.appearance.borderWidth)
                    : Services.ConfigService.config.appearance.borderWidth
                border.color: query.activeFocus
                    ? Services.ThemeService.theme.tokens.focus_ring
                    : Services.ThemeService.theme.tokens.outline_variant

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "search"
                    color: query.activeFocus
                        ? Services.ThemeService.theme.tokens.primary
                        : Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.iconFontFamily
                    font.pixelSize: 22
                }
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
                width: list.width
                height: 60
                radius: Services.ConfigService.config.appearance.radius
                color: mouse.pressed
                    ? Services.ThemeService.theme.tokens.surface_pressed
                    : (index === Services.LauncherService.selectedIndex
                        ? Services.ThemeService.theme.tokens.primary_container
                        : (mouse.containsMouse
                            ? Services.ThemeService.theme.tokens.surface_hover
                            : Services.ThemeService.theme.tokens.surface))
                border.width: Services.ConfigService.config.appearance.borderWidth
                border.color: index === Services.LauncherService.selectedIndex
                    ? Services.ThemeService.theme.tokens.focus_ring
                    : Services.ThemeService.theme.tokens.outline_variant

                Item {
                    id: iconSlot
                    anchors.left: parent.left
                    anchors.leftMargin: 16
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
                        color: index === Services.LauncherService.selectedIndex
                            ? Services.ThemeService.theme.tokens.on_primary_container
                            : Services.ThemeService.theme.tokens.on_surface_disabled
                        font.family: Services.ConfigService.config.appearance.iconFontFamily
                        font.pixelSize: 24
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Column {
                    anchors.left: iconSlot.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: modelData.name
                        color: index === Services.LauncherService.selectedIndex
                            ? Services.ThemeService.theme.tokens.on_primary_container
                            : Services.ThemeService.theme.tokens.on_surface
                        font.family: Services.ConfigService.config.appearance.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: String(modelData.genericName || modelData.comment || "")
                        color: index === Services.LauncherService.selectedIndex
                            ? Services.ThemeService.theme.tokens.on_primary_container
                            : Services.ThemeService.theme.tokens.on_surface_variant
                        opacity: 0.78
                        font.family: Services.ConfigService.config.appearance.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Services.LauncherService.selectedIndex = index
                    onDoubleClicked: Services.LauncherService.launch(index)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0 && Services.LauncherService.lastFailure === ""
                text: Services.LauncherService.query === ""
                    ? "No applications available"
                    : "No matching applications"
                color: Services.ThemeService.theme.tokens.on_surface_variant
                font.family: Services.ConfigService.config.appearance.fontFamily
                font.pixelSize: 16
            }
        }

        Rectangle {
            visible: Services.LauncherService.lastFailure !== ""
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(44, failureText.implicitHeight + 20)
            radius: Services.ConfigService.config.appearance.radius
            color: Services.ThemeService.theme.tokens.surface_variant
            border.width: Services.ConfigService.config.appearance.borderWidth
            border.color: Services.ThemeService.theme.tokens.error

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 10

                Text {
                    id: failureText
                    Layout.fillWidth: true
                    text: Services.LauncherService.lastFailure
                    color: Services.ThemeService.theme.tokens.error
                    wrapMode: Text.Wrap
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 12
                }

                Button {
                    id: retryButton
                    text: "Retry"
                    onClicked: Services.LauncherService.launch(Services.LauncherService.selectedIndex)
                    contentItem: Text {
                        text: retryButton.text
                        color: Services.ThemeService.theme.tokens.on_primary
                        font.family: Services.ConfigService.config.appearance.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        implicitWidth: 68
                        implicitHeight: 32
                        radius: Services.ConfigService.config.appearance.radius
                        color: retryButton.down
                            ? Services.ThemeService.theme.tokens.surface_pressed
                            : Services.ThemeService.theme.tokens.primary
                        border.width: Services.ConfigService.config.appearance.borderWidth
                        border.color: Services.ThemeService.theme.tokens.focus_ring
                    }
                }
            }
        }
        }
    }
}
