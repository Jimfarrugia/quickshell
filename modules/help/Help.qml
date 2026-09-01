import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services" as Services

PanelWindow {
    id: root
    visible: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors { top: true; bottom: true; left: true; right: true }
    screen: {
        const name = Services.CompositorService.focusedMonitorName;
        return Quickshell.screens.find(item => item.name === name)
            || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
    }

    function scrollBy(delta) {
        scrollView.contentY = Math.max(0, Math.min(scrollView.contentHeight - scrollView.height,
            scrollView.contentY + delta));
    }

    function categoryEntries(category) {
        return Services.HelpService.results.filter(entry => entry.category === category);
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Services.HelpService.close()
    }

    Rectangle {
        id: surface
        z: 1
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: parent.height * 0.8
        color: Services.ThemeService.theme.tokens.background
        radius: Services.ConfigService.config.appearance.radius + 2
        border.width: Services.ConfigService.config.appearance.borderWidth
        border.color: Services.ThemeService.theme.tokens.outline_variant

        MouseArea {
            anchors.fill: parent
            onClicked: event => event.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: Services.ConfigService.config.appearance.spacing

            TextField {
                id: query
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                placeholderText: "Search help..."
                placeholderTextColor: Services.ThemeService.theme.tokens.on_surface_placeholder
                text: Services.HelpService.query
                color: Services.ThemeService.theme.tokens.on_surface
                selectionColor: Services.ThemeService.theme.tokens.primary
                selectedTextColor: Services.ThemeService.theme.tokens.on_primary
                font.family: Services.ConfigService.config.appearance.fontFamily
                font.pixelSize: 16
                leftPadding: 16
                onTextChanged: if (text !== Services.HelpService.query)
                    Services.HelpService.setQuery(text)
                Keys.onEscapePressed: Services.HelpService.close()
                Keys.onDownPressed: root.scrollBy(56)
                Keys.onUpPressed: root.scrollBy(-56)
                Keys.onPressed: function(event) {
                    if (event.modifiers === Qt.AltModifier && event.key === Qt.Key_J) {
                        root.scrollBy(56);
                        event.accepted = true;
                    } else if (event.modifiers === Qt.AltModifier && event.key === Qt.Key_K) {
                        root.scrollBy(-56);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_PageDown) {
                        root.scrollBy(list.height);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_PageUp) {
                        root.scrollBy(-list.height);
                        event.accepted = true;
                    }
                }
                background: Rectangle {
                    radius: Services.ConfigService.config.appearance.radius
                    color: Services.ThemeService.theme.tokens.surface_low
                    border.width: 0
                }
            }

            Rectangle {
                visible: Services.HelpService.warning !== ""
                Layout.fillWidth: true
                implicitHeight: warningText.implicitHeight + 20
                radius: Services.ConfigService.config.appearance.radius
                color: Services.ThemeService.theme.tokens.surface_low
                border.width: 0

                Text {
                    id: warningText
                    anchors.fill: parent
                    anchors.margins: 10
                    text: Services.HelpService.warning
                    color: Services.ThemeService.theme.tokens.warning
                    wrapMode: Text.Wrap
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 12
                }
            }

            Flickable {
                id: scrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Services.ConfigService.config.appearance.spacing
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: sectionColumn.implicitHeight

                ColumnLayout {
                    id: sectionColumn
                    width: scrollView.width
                    spacing: Services.ConfigService.config.appearance.spacing * 2

                    Repeater {
                        model: ["keybindings", "commands"]
                        delegate: ColumnLayout {
                            required property string modelData
                            visible: root.categoryEntries(modelData).length > 0
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: modelData === "keybindings" ? "Keybindings" : "Commands"
                                color: Services.ThemeService.theme.tokens.secondary
                                font.family: Services.ConfigService.config.appearance.fontFamily
                                font.pixelSize: 22
                                font.weight: Font.DemiBold
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: Services.ConfigService.config.appearance.spacing
                                rowSpacing: Services.ConfigService.config.appearance.spacing

                                Repeater {
                                    model: root.categoryEntries(parent.parent.modelData)
                                    delegate: Rectangle {
                                        required property var modelData
                                        required property int index
                                        Layout.column: index % 2
                                        Layout.row: Math.floor(index / 2)
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: (sectionColumn.width
                                            - Services.ConfigService.config.appearance.spacing) / 2
                                        Layout.preferredHeight: 60
                                        radius: Services.ConfigService.config.appearance.radius
                                        color: Services.ThemeService.theme.tokens.background

                                        Column {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            spacing: 4

                                            Text {
                                                width: parent.width
                                                text: modelData.title
                                                color: Services.ThemeService.theme.tokens.on_surface
                                                font.family: Services.ConfigService.config.appearance.fontFamily
                                                font.pixelSize: 14
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                width: parent.width
                                                text: modelData.shortcut || modelData.command || ""
                                                visible: text !== ""
                                                color: Services.ThemeService.theme.tokens.on_surface_variant
                                                font.family: modelData.command
                                                    ? Services.ConfigService.config.appearance.monospaceFontFamily
                                                    : Services.ConfigService.config.appearance.fontFamily
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

        }

        Text {
            anchors.centerIn: parent
            width: parent.width - 40
            visible: Services.HelpService.results.length === 0
            text: Services.HelpService.query === "" ? "No help entries" : "No matches."
            color: Services.ThemeService.theme.tokens.on_surface_variant
            font.family: Services.ConfigService.config.appearance.fontFamily
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
        }
    }

    onClosed: Services.HelpService.close()
    Component.onCompleted: Qt.callLater(query.forceActiveFocus)
}
