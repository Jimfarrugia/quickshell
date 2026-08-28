import QtQuick
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
    property alias focusedIndex: wallpaperGrid.currentIndex
    readonly property string focusedWallpaperFileName: wallpaperGrid.currentItem
        ? wallpaperGrid.currentItem.fileName : ""

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

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: "Select Wallpaper"
                    color: Services.ThemeService.theme.tokens.on_surface_panel
                    font.family: Services.ConfigService.config.appearance.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }
            }

            GridView {
                id: wallpaperGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                clip: true
                focus: true
                readonly property real gridGap: Services.ConfigService.config.appearance.spacing
                readonly property int columnCount: root.columnsForWidth(root.width,
                    root.screen === null ? 0 : root.screen.width)
                readonly property real cardWidth: root.cardWidthForGrid(width, columnCount, gridGap)
                readonly property real cardHeight: cardWidth * 9 / 16
                cellWidth: width / columnCount
                cellHeight: cardHeight + gridGap
                contentHeight: count === 0 ? 0
                    : Math.ceil(count / columnCount) * cellHeight - gridGap
                model: root.wallpaperModel
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
                        moveCurrentIndexUp();
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
                    text: "No wallpapers found for this theme"
                    color: Services.ThemeService.theme.tokens.on_surface_variant
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
                        : Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideMiddle
                    text: root.focusedWallpaperFileName
                    color: Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 11
                }

            }
        }
    }

    Component.onCompleted: wallpaperGrid.forceActiveFocus()
}
