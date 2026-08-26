import QtQuick
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

    function applyWallpaper(path) {
        if (Services.WallpaperService.operation === "pending"
                || path === Services.WallpaperService.appliedPath) return false;
        return Services.WallpaperService.requestWallpaper(path);
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
            spacing: 16

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "QE WALLPAPERS"
                        color: Services.ThemeService.theme.tokens.secondary
                        font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.5
                    }

                    Text {
                        text: "Choose a wallpaper for the current theme"
                        color: Services.ThemeService.theme.tokens.on_surface_panel
                        font.family: Services.ConfigService.config.appearance.fontFamily
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: 17
                    color: closeHover.hovered ? Services.ThemeService.theme.tokens.surface_hover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        color: Services.ThemeService.theme.tokens.on_surface_panel
                        font.family: Services.ConfigService.config.appearance.iconFontFamily
                        font.pixelSize: 20
                    }

                    HoverHandler { id: closeHover }
                    TapHandler { onTapped: Services.SurfaceService.closeWallpaperSelector() }
                }
            }

            GridView {
                id: wallpaperGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                focus: true
                cellWidth: Math.max(220, width / 3)
                cellHeight: 160
                model: Services.WallpaperService.catalogModel
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
                    width: wallpaperGrid.cellWidth
                    height: wallpaperGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: Services.ConfigService.config.appearance.radius
                        opacity: delegateRoot.selectable ? 1 : 0.52
                        color: cardTap.pressed ? Services.ThemeService.theme.tokens.surface_pressed
                            : (cardHover.hovered ? Services.ThemeService.theme.tokens.surface_hover
                                : Services.ThemeService.theme.tokens.surface)
                        border.width: delegateRoot.GridView.isCurrentItem ? 2 : Services.ConfigService.config.appearance.borderWidth
                        border.color: delegateRoot.GridView.isCurrentItem
                            ? Services.ThemeService.theme.tokens.focus_ring
                            : Services.ThemeService.theme.tokens.outline_variant

                        Image {
                            anchors.fill: parent
                            anchors.margins: 6
                            source: delegateRoot.thumbnailUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 6
                            height: 30
                            color: Services.ThemeService.theme.tokens.scrim

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideMiddle
                                text: delegateRoot.fileName
                                color: Services.ThemeService.theme.tokens.on_surface
                                font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                                font.pixelSize: 10
                            }
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

                Text {
                    Layout.fillWidth: true
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
                    text: Services.WallpaperService.generationStatus === "pending"
                        ? "Generating Wallpaper theme..."
                        : Services.WallpaperService.generationStatus === "succeeded"
                            ? "Wallpaper theme generated"
                            : Services.WallpaperService.generationStatus === "unavailable"
                                ? "Matugen unavailable"
                                : "Click a wallpaper to apply"
                    color: Services.WallpaperService.generationStatus === "failed"
                        ? Services.ThemeService.theme.tokens.error
                        : Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 11
                }

                Text {
                    text: "h/j/k/l navigate / q or Esc close / Enter apply"
                    color: Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 11
                }
            }
        }
    }

    Component.onCompleted: wallpaperGrid.forceActiveFocus()
}
