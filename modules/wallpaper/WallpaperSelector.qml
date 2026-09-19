import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import "../../services" as Services

FloatingWindow {
    id: root

    title: "QE Wallpaper Selector"
    visible: true
    implicitWidth: 760
    implicitHeight: 560
    color: "transparent"

    property var wallpaperModel: Services.WallpaperService.catalogModel
    property string selectedWallpaperThemeId: Services.ThemeService.activeThemeId
    property string focusTarget: "grid"
    property alias focusedIndex: wallpaperGrid.currentIndex
    readonly property string focusedWallpaperFileName: wallpaperGrid.currentItem
        ? wallpaperGrid.currentItem.fileName : ""
    readonly property int wallpaperCount: wallpaperGrid.count
    readonly property var availableThemes: {
        const catalog = Services.ThemeService.catalog;
        if (catalog.some(theme => theme.id === Services.ThemeService.activeThemeId))
            return catalog;
        return [Services.ThemeService.theme].concat(catalog);
    }
    readonly property var wallpaperSources: [{ id: "*", name: "Show All" }]
        .concat(root.availableThemes)

    function focusItem(target) {
        root.focusTarget = target;
        Qt.callLater(function() {
            if (target === "dropdown") themeMenu.forceActiveFocus();
            else wallpaperGrid.forceActiveFocus();
        });
    }

    function rebuildWallpaperModel() {
        filteredWallpaperModel.clear();
        if (root.wallpaperModel === null || root.wallpaperModel === undefined) return;
        for (let index = 0; index < root.wallpaperModel.count; ++index) {
            const wallpaper = root.wallpaperModel.get(index);
            if (root.selectedWallpaperThemeId !== "*" && wallpaper.themeId !== undefined
                    && wallpaper.themeId !== root.selectedWallpaperThemeId) continue;
            filteredWallpaperModel.append({
                thumbnailUrl: wallpaper.thumbnailUrl,
                sourcePath: wallpaper.sourcePath,
                fileName: wallpaper.fileName
            });
        }
        wallpaperGrid.currentIndex = filteredWallpaperModel.count > 0 ? 0 : -1;
    }

    function syncSelectedTheme() {
        if (root.selectedWallpaperThemeId === "*"
                || root.availableThemes.some(theme => theme.id === root.selectedWallpaperThemeId)) return;
        root.selectedWallpaperThemeId = Services.ThemeService.activeThemeId;
    }

    function applyWallpaper(path) {
        if (Services.WallpaperService.operation === "pending"
                || path === Services.WallpaperService.appliedPath) return false;
        return Services.WallpaperService.requestWallpaper(path);
    }

    function columnsForWidth(windowWidth, displayWidth) {
        if (displayWidth <= 0) return 4;
        if (windowWidth < displayWidth * 0.25) return 1;
        if (windowWidth < displayWidth * 0.4) return 2;
        if (windowWidth < displayWidth * 0.6) return 3;
        return 4;
    }

    function cardWidthForGrid(gridWidth, columns, gap) {
        return Math.max(0, (gridWidth - gap * (columns - 1)) / columns);
    }

    function cardOffsetForColumn(column, columns, gap) {
        return column * gap / columns;
    }

    onClosed: Services.SurfaceService.closeWallpaperSelector()
    onWallpaperModelChanged: rebuildWallpaperModel()
    onSelectedWallpaperThemeIdChanged: rebuildWallpaperModel()

    Connections {
        target: root.wallpaperModel
        ignoreUnknownSignals: true
        function onCountChanged() { root.rebuildWallpaperModel(); }
    }

    Connections {
        target: Services.ThemeService
        function onCatalogChanged() { root.syncSelectedTheme(); }
        function onActiveThemeIdChanged() { root.syncSelectedTheme(); }
    }

    ListModel {
        id: filteredWallpaperModel
    }

    Rectangle {
        anchors.fill: parent
        color: Services.ThemeService.theme.tokens.surface_panel
        // Hyprland owns the outer window border and corner clipping.
        radius: 0
        border.width: 0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 5

                Text {
                    text: "QE WALLPAPERS"
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
                    model: root.wallpaperSources
                    textRole: "name"
                    valueRole: "id"
                    currentIndex: Math.max(0, root.wallpaperSources.findIndex(
                        source => source.id === root.selectedWallpaperThemeId))
                    displayText: `Theme: ${currentText}`
                    focus: root.focusTarget === "dropdown"
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    onActivated: {
                        root.selectedWallpaperThemeId = currentValue;
                        root.focusTarget = "dropdown";
                    }
                    onActiveFocusChanged: if (activeFocus) root.focusTarget = "dropdown"

                    Keys.onEscapePressed: {
                        if (themeMenu.popup.visible) themeMenu.popup.close();
                        else Services.SurfaceService.closeWallpaperSelector();
                    }
                    Keys.onPressed: function(event) {
                        if (event.modifiers !== Qt.NoModifier) return;
                        if (event.key === Qt.Key_Q) {
                            Services.SurfaceService.closeWallpaperSelector();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            themeMenu.popup.open();
                            event.accepted = true;
                        } else if (!themeMenu.popup.visible && event.key === Qt.Key_L) {
                            themeMenu.popup.open();
                            event.accepted = true;
                        } else if (!themeMenu.popup.visible && event.key === Qt.Key_J) {
                            root.focusItem("grid");
                            event.accepted = true;
                        }
                    }
                    Keys.onReleased: function(event) {
                        if (event.modifiers === Qt.NoModifier
                                && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter))
                            event.accepted = true;
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
                            : Services.ThemeService.theme.tokens.on_surface_subdued
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
                                    Services.SurfaceService.closeWallpaperSelector();
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
                                    root.selectedWallpaperThemeId = root.wallpaperSources[currentIndex].id;
                                    themePopup.close();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_K) {
                                    currentIndex = Math.max(currentIndex - 1, 0);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.selectedWallpaperThemeId = root.wallpaperSources[currentIndex].id;
                                    themeMenu.popup.close();
                                    event.accepted = true;
                                }
                            }
                            Keys.onReleased: function(event) {
                                if (event.modifiers === Qt.NoModifier
                                        && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter))
                                    event.accepted = true;
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

            GridView {
                id: wallpaperGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                clip: true
                focus: root.focusTarget === "grid"
                readonly property real gridGap: Services.ConfigService.config.appearance.spacing
                readonly property int columnCount: root.columnsForWidth(root.width,
                    root.screen === null ? 0 : root.screen.width)
                readonly property real cardWidth: root.cardWidthForGrid(width, columnCount, gridGap)
                readonly property real cardHeight: cardWidth * 9 / 16
                cellWidth: width / columnCount
                cellHeight: cardHeight + gridGap
                contentHeight: count === 0 ? 0
                    : Math.ceil(count / columnCount) * cellHeight - gridGap
                model: filteredWallpaperModel
                currentIndex: 0

                Keys.onEscapePressed: Services.SurfaceService.closeWallpaperSelector()
                Keys.onPressed: function(event) {
                    if (event.modifiers !== Qt.NoModifier) return;

                    switch (event.key) {
                    case Qt.Key_H:
                        moveCurrentIndexLeft();
                        break;
                    case Qt.Key_J:
                        moveCurrentIndexDown();
                        break;
                    case Qt.Key_K:
                        if (currentIndex < columnCount) root.focusItem("dropdown");
                        else moveCurrentIndexUp();
                        break;
                    case Qt.Key_L:
                        moveCurrentIndexRight();
                        break;
                    case Qt.Key_Q:
                        Services.SurfaceService.closeWallpaperSelector();
                        break;
                    default:
                        return;
                    }

                    event.accepted = true;
                }
                Keys.onEnterPressed: {
                    if (currentItem !== null && currentItem.selectable)
                        root.applyWallpaper(currentItem.sourcePath);
                }
                Keys.onReturnPressed: {
                    if (currentItem !== null && currentItem.selectable)
                        root.applyWallpaper(currentItem.sourcePath);
                }
                onActiveFocusChanged: if (activeFocus) root.focusTarget = "grid"

                delegate: Item {
                    id: delegateRoot
                    required property url thumbnailUrl
                    required property string sourcePath
                    required property string fileName
                    required property int index
                    readonly property bool selectable: Services.WallpaperService.operation !== "pending"
                        && sourcePath !== Services.WallpaperService.appliedPath
                    readonly property int gridColumn: index % wallpaperGrid.columnCount
                    readonly property real imageInset: delegateRoot.GridView.isCurrentItem
                        ? 2 : Services.ConfigService.config.appearance.borderWidth
                    width: wallpaperGrid.cellWidth
                    height: wallpaperGrid.cellHeight

                    Rectangle {
                        x: root.cardOffsetForColumn(delegateRoot.gridColumn,
                            wallpaperGrid.columnCount, wallpaperGrid.gridGap)
                        width: wallpaperGrid.cardWidth
                        height: wallpaperGrid.cardHeight
                        radius: Services.ConfigService.config.appearance.radius
                        opacity: delegateRoot.selectable ? 1 : 0.52
                        color: cardTap.pressed ? Services.ThemeService.theme.tokens.surface_pressed
                            : (cardHover.hovered ? Services.ThemeService.theme.tokens.surface_hover
                                : Services.ThemeService.theme.tokens.surface)
                        border.width: 0

                        Image {
                            id: wallpaperImage
                            anchors.fill: parent
                            source: delegateRoot.thumbnailUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: false
                        }

                        Item {
                            id: imageMask
                            anchors.fill: parent
                            visible: false
                            layer.enabled: true

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: delegateRoot.imageInset
                                radius: Math.max(0, Services.ConfigService.config.appearance.radius
                                    - delegateRoot.imageInset)
                                color: "white"
                            }
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: wallpaperImage
                            maskEnabled: true
                            maskSource: imageMask
                            autoPaddingEnabled: false
                        }

                        Rectangle {
                            anchors.fill: parent
                            z: 2
                            radius: Services.ConfigService.config.appearance.radius
                            color: "transparent"
                            border.width: delegateRoot.GridView.isCurrentItem ? 2 : Services.ConfigService.config.appearance.borderWidth
                            border.color: delegateRoot.GridView.isCurrentItem
                                ? Services.ThemeService.theme.tokens.focus_ring
                                : Services.ThemeService.theme.tokens.outline_variant
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: delegateRoot.GridView.isCurrentItem ? 2 : 0
                            z: 3
                            radius: Services.ConfigService.config.appearance.radius
                            color: "transparent"
                            border.width: delegateRoot.GridView.isCurrentItem ? 2 : 0
                            border.color: Services.ThemeService.theme.tokens.outline_variant
                        }

                        HoverHandler {
                            id: cardHover
                            enabled: delegateRoot.selectable
                        }
                        TapHandler {
                            id: cardTap
                            enabled: delegateRoot.selectable
                            onTapped: {
                                wallpaperGrid.currentIndex = delegateRoot.index;
                                root.applyWallpaper(delegateRoot.sourcePath);
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: wallpaperGrid.count === 0
                    text: root.selectedWallpaperThemeId === "*"
                        ? "No wallpapers found"
                        : "No wallpapers found for this theme"
                    color: Services.ThemeService.theme.tokens.on_surface_subdued
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 16
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: Services.WallpaperService.operation === "pending"
                        ? "Applying wallpaper..."
                        : Services.WallpaperService.operation === "failed"
                            ? Services.WallpaperService.lastError
                        : `${wallpaperGrid.count} wallpapers`
                    color: Services.WallpaperService.operation === "failed"
                        ? Services.ThemeService.theme.tokens.error
                        : Services.ThemeService.theme.tokens.on_surface_subdued
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideMiddle
                    text: root.focusedWallpaperFileName
                    color: Services.ThemeService.theme.tokens.on_surface_subdued
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 11
                }

            }
        }
    }

    Component.onCompleted: {
        root.rebuildWallpaperModel();
        root.focusItem("grid");
    }
}
