import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import "../../components" as Components
import "../../services" as Services

FloatingWindow {
    id: root

    title: "QE Palette Viewer"
    visible: true
    implicitWidth: 680
    implicitHeight: 720
    color: "transparent"

    property string viewMode: "tokens"
    property string focusTarget: "grid"
    property string viewedThemeId: Services.ThemeService.activeThemeId
    readonly property var availableThemes: {
        const catalog = Services.ThemeService.catalog;
        if (catalog.some(theme => theme.id === Services.ThemeService.activeThemeId))
            return catalog;
        return [Services.ThemeService.theme].concat(catalog);
    }
    readonly property var viewedTheme: {
        const selected = root.availableThemes.find(theme => theme.id === root.viewedThemeId);
        return selected || Services.ThemeService.theme;
    }
    readonly property bool twoColumns: root.screen !== null && root.width > root.screen.width * 0.25
    readonly property var entries: viewMode === "tokens"
        ? Object.keys(root.viewedTheme.tokens)
        : Object.keys(root.viewedTheme.palette || {})

    function hexValue(value) {
        const normalized = String(value).toLowerCase();
        return normalized.length === 9 && normalized.slice(1, 3) === "ff"
            ? `#${normalized.slice(3)}` : normalized;
    }

    function luminance(value) {
        const normalized = String(value).toLowerCase();
        if (!/^#[0-9a-f]{6}([0-9a-f]{2})?$/.test(normalized)) return 0.5;
        const offset = normalized.length === 9 ? 3 : 1;
        const channel = index => parseInt(normalized.slice(offset + index * 2, offset + index * 2 + 2), 16) / 255;
        const linear = channelValue => channelValue <= 0.03928
            ? channelValue / 12.92 : Math.pow((channelValue + 0.055) / 1.055, 2.4);
        return 0.2126 * linear(channel(0)) + 0.7152 * linear(channel(1)) + 0.0722 * linear(channel(2));
    }

    function fallbackTextColor(value) {
        return luminance(value) > 0.5 ? darkestColor() : lightestColor();
    }

    function darkestColor() {
        const values = Object.values(root.viewedTheme.tokens || {})
            .concat(Object.values(root.viewedTheme.palette || {}));
        return values.length === 0 ? "#000000" : values.reduce((darkest, candidate) =>
            luminance(candidate) < luminance(darkest) ? candidate : darkest);
    }

    function lightestColor() {
        const values = Object.values(root.viewedTheme.tokens || {})
            .concat(Object.values(root.viewedTheme.palette || {}));
        return values.length === 0 ? "#ffffff" : values.reduce((lightest, candidate) =>
            luminance(candidate) > luminance(lightest) ? candidate : lightest);
    }

    function textColor(name, value) {
        if (viewMode === "tokens") {
            const pairedName = name.startsWith("on_") ? "" : `on_${name}`;
            const paired = pairedName ? root.viewedTheme.tokens[pairedName] : null;
            if (paired) return paired;
        }
        return fallbackTextColor(value);
    }

    function copyValue(value) {
        Quickshell.clipboardText = hexValue(value);
    }

    function focusItem(target) {
        root.focusTarget = target;
        Qt.callLater(function() {
            if (target === "dropdown") themeMenu.forceActiveFocus();
            else if (target === "toggle") modeToggle.forceActiveFocus();
            else list.forceActiveFocus();
        });
    }

    onClosed: Services.SurfaceService.closePaletteViewer()

    function syncViewedTheme() {
        if (root.availableThemes.some(theme => theme.id === root.viewedThemeId)) return;
        root.viewedThemeId = Services.ThemeService.activeThemeId;
    }

    Connections {
        target: Services.ThemeService
        function onCatalogChanged() { root.syncViewedTheme(); }
        function onActiveThemeIdChanged() { root.syncViewedTheme(); }
    }

    Rectangle {
        anchors.fill: parent
        color: Services.ThemeService.theme.tokens.surface_panel
        radius: 0
        border.width: 0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    Layout.fillWidth: true
                    text: "QE PALETTE"
                    color: Services.ThemeService.theme.tokens.secondary
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.5
                }

                ComboBox {
                        id: themeMenu
                        implicitHeight: 26
                        topPadding: 0
                        bottomPadding: 0
                        implicitWidth: contentItem.implicitWidth
                        model: root.availableThemes
                        textRole: "name"
                        valueRole: "id"
                        currentIndex: Math.max(0, root.availableThemes.findIndex(
                            theme => theme.id === root.viewedThemeId))
                        displayText: `Theme: ${currentText}`
                        focus: root.focusTarget === "dropdown"
                        font.family: Services.ConfigService.config.appearance.fontFamily
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        onActivated: {
                            root.viewedThemeId = currentValue;
                            root.focusTarget = "dropdown";
                        }
                        onActiveFocusChanged: if (activeFocus) root.focusTarget = "dropdown"

                        Keys.onEscapePressed: {
                            if (themeMenu.popup.visible) themeMenu.popup.close();
                            else Services.SurfaceService.closePaletteViewer();
                        }
                        Keys.onPressed: function(event) {
                            if (event.modifiers !== Qt.NoModifier) return;
                            if (event.key === Qt.Key_Q) {
                                Services.SurfaceService.closePaletteViewer();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                themeMenu.popup.open();
                                event.accepted = true;
                            } else if (!themeMenu.popup.visible && event.key === Qt.Key_L) {
                                themeMenu.popup.open();
                                event.accepted = true;
                            } else if (!themeMenu.popup.visible && event.key === Qt.Key_J) {
                                root.focusItem("toggle");
                                event.accepted = true;
                            }
                        }
                        Keys.onReleased: function(event) {
                            if (event.modifiers === Qt.NoModifier
                                    && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                                event.accepted = true;
                            }
                        }

                        indicator: Item {
                            implicitWidth: 0
                            implicitHeight: 0
                        }

                        contentItem: Text {
                            leftPadding: 0
                            text: themeMenu.displayText
                            color: themeMenu.hovered || themeMenu.activeFocus
                                ? Services.ThemeService.theme.tokens.link
                                : Services.ThemeService.theme.tokens.on_surface_panel
                            font: themeMenu.font
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: "transparent"
                            radius: Services.ConfigService.config.appearance.radius
                        }

                        delegate: ItemDelegate {
                            id: themeDelegate
                            required property var modelData
                            required property int index
                            readonly property bool selectedOption: themeMenu.currentIndex === index
                            width: themeMenu.width
                            implicitHeight: 38
                            highlighted: themeOptions.currentIndex === index
                            text: modelData.name
                            contentItem: Text {
                                text: themeDelegate.modelData.name
                                color: themeDelegate.selectedOption
                                    ? Services.ThemeService.theme.tokens.on_primary
                                    : Services.ThemeService.theme.tokens.on_surface
                                font.family: themeMenu.font.family
                                font.weight: themeMenu.font.weight
                                font.pixelSize: 14
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 12
                            }
                            background: Rectangle {
                                color: themeDelegate.selectedOption
                                    ? Services.ThemeService.theme.tokens.primary
                                    : (themeDelegate.highlighted || themeDelegate.hovered
                                        ? Services.ThemeService.theme.tokens.surface_hover
                                        : Services.ThemeService.theme.tokens.surface)
                            }
                        }

                        popup: Popup {
                            id: themePopup
                            y: themeMenu.height
                            width: themeMenu.width
                            padding: 4
                            focus: true
                            onOpened: Qt.callLater(themeOptions.forceActiveFocus)
                            onClosed: Qt.callLater(themeMenu.forceActiveFocus)

                            contentItem: ListView {
                                id: themeOptions
                                clip: true
                                focus: true
                                implicitHeight: contentHeight
                                model: themeMenu.popup.visible ? themeMenu.delegateModel : null
                                currentIndex: themeMenu.highlightedIndex
                                Keys.onEscapePressed: themePopup.close()
                                Keys.onPressed: function(event) {
                                    if (event.modifiers !== Qt.NoModifier && event.key !== Qt.Key_Escape)
                                        return;
                                    if (event.key === Qt.Key_Q) {
                                        Services.SurfaceService.closePaletteViewer();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Escape) {
                                        themePopup.close();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_J) {
                                        currentIndex = Math.min(currentIndex + 1, count - 1);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_H) {
                                        themePopup.close();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_L) {
                                        root.viewedThemeId = root.availableThemes[currentIndex].id;
                                        themePopup.close();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_K) {
                                        currentIndex = Math.max(currentIndex - 1, 0);
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        root.viewedThemeId = root.availableThemes[currentIndex].id;
                                        themeMenu.popup.close();
                                        event.accepted = true;
                                    }
                                }
                                Keys.onReleased: function(event) {
                                    if (event.modifiers === Qt.NoModifier
                                            && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                                        event.accepted = true;
                                    }
                                }
                            }

                            background: Rectangle {
                                color: Services.ThemeService.theme.tokens.surface
                                border.width: Services.ConfigService.config.appearance.borderWidth
                                border.color: Services.ThemeService.theme.tokens.outline_variant
                                radius: Services.ConfigService.config.appearance.radius
                            }
                            }
                        }
                    }

            Components.SegmentedToggle {
                id: modeToggle
                Layout.fillWidth: true
                labels: ["Tokens", "Palette"]
                checked: root.viewMode === "palette"
                focus: root.focusTarget === "toggle"
                onActiveFocusChanged: if (activeFocus) root.focusTarget = "toggle"
                onToggled: root.viewMode = root.viewMode === "tokens" ? "palette" : "tokens"

                Keys.onEscapePressed: Services.SurfaceService.closePaletteViewer()
                Keys.onPressed: function(event) {
                    if (event.modifiers !== Qt.NoModifier) return;

                    if (event.key === Qt.Key_Q || event.key === Qt.Key_Escape) {
                        Services.SurfaceService.closePaletteViewer();
                    } else if (event.key === Qt.Key_K) {
                        root.focusItem("dropdown");
                    } else if (event.key === Qt.Key_J) {
                        root.focusItem("grid");
                    } else if (event.key === Qt.Key_H) {
                        root.viewMode = "tokens";
                    } else if (event.key === Qt.Key_L) {
                        root.viewMode = "palette";
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        modeToggle.activate();
                    } else {
                        return;
                    }

                    event.accepted = true;
                }

            }

            GridView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: width / (root.twoColumns ? 2 : 1)
                cellHeight: 60
                model: root.entries
                focus: root.focusTarget === "grid"
                onCountChanged: currentIndex = Math.min(currentIndex, Math.max(0, count - 1))
                boundsBehavior: Flickable.StopAtBounds
                Keys.onEscapePressed: Services.SurfaceService.closePaletteViewer()
                Keys.onPressed: function(event) {
                    if (event.modifiers !== Qt.NoModifier) return;

                    if (event.key === Qt.Key_Tab) {
                        root.viewMode = root.viewMode === "tokens" ? "palette" : "tokens";
                        currentIndex = Math.min(currentIndex, Math.max(0, count - 1));
                        event.accepted = true;
                        return;
                    }

                    switch (event.key) {
                    case Qt.Key_Escape:
                        Services.SurfaceService.closePaletteViewer();
                        break;
                    case Qt.Key_H:
                        if (root.twoColumns) moveCurrentIndexLeft();
                        break;
                    case Qt.Key_J:
                        moveCurrentIndexDown();
                        break;
                    case Qt.Key_K:
                        if (currentIndex < (root.twoColumns ? 2 : 1)) root.focusItem("toggle");
                        else moveCurrentIndexUp();
                        break;
                    case Qt.Key_L:
                        if (root.twoColumns) moveCurrentIndexRight();
                        break;
                    case Qt.Key_Q:
                        Services.SurfaceService.closePaletteViewer();
                        break;
                    case Qt.Key_Space:
                        if (currentItem !== null) currentItem.copyColor();
                        break;
                    default:
                        return;
                    }

                    event.accepted = true;
                }
                Keys.onEnterPressed: if (currentItem !== null) currentItem.copyColor()
                Keys.onReturnPressed: if (currentItem !== null) currentItem.copyColor()
                onActiveFocusChanged: if (activeFocus) root.focusTarget = "grid"

                delegate: Item {
                    id: delegateRoot
                    required property string modelData
                    required property int index
                    width: list.cellWidth
                    height: list.cellHeight
                    readonly property int gridColumns: root.twoColumns ? 2 : 1
                    readonly property int gridColumn: index % gridColumns
                    readonly property int gridRow: Math.floor(index / gridColumns)
                    readonly property int lastGridRow: Math.floor((list.count - 1) / gridColumns)
                    readonly property real gridGap: Services.ConfigService.config.appearance.spacing
                    readonly property color rowColor: root.viewMode === "tokens"
                        ? root.viewedTheme.tokens[modelData]
                        : root.viewedTheme.palette[modelData]
                    readonly property color foreground: root.textColor(modelData, rowColor)
                    property bool copied: false

                    function copyColor() {
                        root.copyValue(rowColor);
                        copied = true;
                        copiedTimer.restart();
                    }

                    Rectangle {
                        id: focusFrame
                        anchors.fill: parent
                        anchors.leftMargin: delegateRoot.gridColumn === 0 ? 0 : delegateRoot.gridGap / 2
                        anchors.rightMargin: delegateRoot.gridColumn === delegateRoot.gridColumns - 1 ? 0 : delegateRoot.gridGap / 2
                        anchors.topMargin: delegateRoot.gridRow === 0 ? 0 : delegateRoot.gridGap / 2
                        anchors.bottomMargin: delegateRoot.gridRow === delegateRoot.lastGridRow ? 0 : delegateRoot.gridGap / 2
                        z: 1
                        radius: Services.ConfigService.config.appearance.radius + 2
                        color: "transparent"
                        border.width: list.activeFocus && delegateRoot.GridView.isCurrentItem ? 2 : 0
                        border.color: Services.ThemeService.theme.tokens.focus_ring
                    }

                    Rectangle {
                        id: row
                        anchors.fill: parent
                        anchors.leftMargin: delegateRoot.gridColumn === 0 ? 0 : delegateRoot.gridGap / 2
                        anchors.rightMargin: delegateRoot.gridColumn === delegateRoot.gridColumns - 1 ? 0 : delegateRoot.gridGap / 2
                        anchors.topMargin: delegateRoot.gridRow === 0 ? 0 : delegateRoot.gridGap / 2
                        anchors.bottomMargin: delegateRoot.gridRow === delegateRoot.lastGridRow ? 0 : delegateRoot.gridGap / 2
                        radius: Services.ConfigService.config.appearance.radius
                        color: delegateRoot.rowColor
                        border.width: Services.ConfigService.config.appearance.borderWidth
                        border.color: Services.ThemeService.theme.tokens.outline_variant

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 8
                            spacing: 12

                            Text {
                                Layout.fillWidth: true
                                text: delegateRoot.modelData
                                color: delegateRoot.foreground
                                font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.hexValue(delegateRoot.rowColor)
                                color: delegateRoot.foreground
                                font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                                font.pixelSize: 12
                            }

                            Rectangle {
                                implicitWidth: 34
                                implicitHeight: 34
                                radius: 17
                                color: copyHover.hovered ? Qt.rgba(delegateRoot.foreground.r,
                                    delegateRoot.foreground.g, delegateRoot.foreground.b, 0.2) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: delegateRoot.copied ? "check" : "content_copy"
                                    color: delegateRoot.foreground
                                    font.family: Services.ConfigService.config.appearance.iconFontFamily
                                    font.pixelSize: 18
                                }
                                HoverHandler { id: copyHover }
                                TapHandler {
                                    onTapped: {
                                        list.currentIndex = delegateRoot.index;
                                        delegateRoot.copyColor();
                                    }
                                }
                                Timer {
                                    id: copiedTimer
                                    interval: 1200
                                    onTriggered: delegateRoot.copied = false
                                }
                            }
                        }

                        TapHandler { onTapped: list.currentIndex = delegateRoot.index }
                    }

                    Rectangle {
                        id: innerFocusFrame
                        anchors.fill: parent
                        anchors.leftMargin: (delegateRoot.gridColumn === 0 ? 0 : delegateRoot.gridGap / 2)
                            + (delegateRoot.GridView.isCurrentItem ? 2 : 0)
                        anchors.rightMargin: (delegateRoot.gridColumn === delegateRoot.gridColumns - 1 ? 0 : delegateRoot.gridGap / 2)
                            + (delegateRoot.GridView.isCurrentItem ? 2 : 0)
                        anchors.topMargin: (delegateRoot.gridRow === 0 ? 0 : delegateRoot.gridGap / 2)
                            + (delegateRoot.GridView.isCurrentItem ? 2 : 0)
                        anchors.bottomMargin: (delegateRoot.gridRow === delegateRoot.lastGridRow ? 0 : delegateRoot.gridGap / 2)
                            + (delegateRoot.GridView.isCurrentItem ? 2 : 0)
                        z: 2
                        radius: Services.ConfigService.config.appearance.radius
                        color: "transparent"
                        border.width: list.activeFocus && delegateRoot.GridView.isCurrentItem ? 2 : 0
                        border.color: Services.ThemeService.theme.tokens.outline_variant
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: `${root.entries.length} ${root.viewMode}`
                    color: Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 11
                }
                Text {
                    text: "Click copy to copy a color / q or Esc close"
                    color: Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 11
                }
            }
        }
    }

    Component.onCompleted: {
        list.currentIndex = 0;
        root.focusItem("grid");
    }
}
