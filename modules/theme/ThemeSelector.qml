import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services" as Services

FloatingWindow {
    id: root

    title: "QE Theme Selector"
    visible: true
    implicitWidth: 660
    implicitHeight: 430
    color: "transparent"

    function applyTheme(id) {
        if (Services.ThemeService.operation === "pending"
                || Services.ThemeService.externalOperation === "pending") return false;
        return Services.ThemeService.requestTheme(id);
    }

    onClosed: Services.SurfaceService.closeThemeSelector()

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
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "QE THEMES"
                        color: Services.ThemeService.theme.tokens.secondary
                        font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.5
                    }

                    Text {
                        text: "Choose the shell's visual language"
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
                    TapHandler { onTapped: Services.SurfaceService.closeThemeSelector() }
                }
            }

            GridView {
                id: themeGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                focus: true
                cellWidth: Math.max(280, width / 2)
                cellHeight: 230
                model: Services.ThemeService.catalog
                currentIndex: Math.max(0, Services.ThemeService.catalog.findIndex(theme => theme.id === Services.ThemeService.activeThemeId))

                Keys.onEscapePressed: Services.SurfaceService.closeThemeSelector()
                Keys.onEnterPressed: {
                    if (currentItem !== null) root.applyTheme(currentItem.themeId);
                }
                Keys.onReturnPressed: {
                    if (currentItem !== null) root.applyTheme(currentItem.themeId);
                }

                delegate: Item {
                    id: delegateRoot
                    required property var modelData
                    required property int index
                    readonly property string themeId: modelData.id
                    readonly property bool selectable: Services.ThemeService.operation !== "pending"
                        && Services.ThemeService.externalOperation !== "pending"
                        && themeId !== Services.ThemeService.activeThemeId
                    width: themeGrid.cellWidth
                    height: themeGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: Services.ConfigService.config.appearance.radius + 2
                        opacity: delegateRoot.selectable ? 1 : 0.52
                        color: modelData.id === Services.ThemeService.activeThemeId
                            ? modelData.tokens.primary_container
                            : (cardTap.pressed ? modelData.tokens.surface_pressed
                                : (cardHover.hovered ? modelData.tokens.surface_hover : modelData.tokens.surface))
                        border.width: delegateRoot.GridView.isCurrentItem ? 2 : Services.ConfigService.config.appearance.borderWidth
                        border.color: delegateRoot.GridView.isCurrentItem ? modelData.tokens.focus_ring : modelData.tokens.outline_variant

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: modelData.name
                                        color: modelData.id === Services.ThemeService.activeThemeId
                                            ? modelData.tokens.on_primary_container : modelData.tokens.on_surface
                                        font.family: Services.ConfigService.config.appearance.fontFamily
                                        font.pixelSize: 18
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: `${modelData.id} / ${modelData.variant}`
                                        color: modelData.id === Services.ThemeService.activeThemeId
                                            ? modelData.tokens.on_primary_container : modelData.tokens.on_surface_variant
                                        opacity: 0.78
                                        font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                                        font.pixelSize: 11
                                    }
                                }

                                Text {
                                    visible: modelData.id === Services.ThemeService.activeThemeId
                                    text: "ACTIVE"
                                    color: modelData.tokens.on_primary_container
                                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Repeater {
                                    model: [
                                        modelData.tokens.primary,
                                        modelData.tokens.secondary,
                                        modelData.tokens.link,
                                        modelData.tokens.warning,
                                        modelData.tokens.error
                                    ]

                                    Rectangle {
                                        required property color modelData
                                        Layout.fillWidth: true
                                        implicitHeight: 58
                                        radius: 4
                                        color: modelData
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.id === Services.ThemeService.activeThemeId
                                    ? "Currently active"
                                    : (Services.ThemeService.operation === "pending"
                                        || Services.ThemeService.externalOperation === "pending")
                                        ? "Theme apply in progress"
                                        : "Select to apply"
                                color: modelData.id === Services.ThemeService.activeThemeId
                                    ? modelData.tokens.on_primary_container : modelData.tokens.on_surface_variant
                                font.family: Services.ConfigService.config.appearance.fontFamily
                                font.pixelSize: 12
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
                                themeGrid.currentIndex = delegateRoot.index;
                                root.applyTheme(delegateRoot.themeId);
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: Services.ThemeService.operation === "pending"
                        ? "Applying theme..."
                        : `${Services.ThemeService.catalog.length} validated themes`
                    color: Services.ThemeService.operation === "failed"
                        ? Services.ThemeService.theme.tokens.error
                        : Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 11
                }

                Text {
                    readonly property string failedTargets: Services.ThemeService.externalResults
                        .filter(result => result.status === "failed")
                        .map(result => result.target)
                        .join(", ")
                    text: Services.ThemeService.externalStatus === "pending"
                        ? "External apps: applying..."
                        : Services.ThemeService.externalStatus === "success"
                            ? "External apps: applied"
                            : Services.ThemeService.externalStatus === "partial"
                                ? `External partial: ${failedTargets || "state persistence"}`
                            : Services.ThemeService.externalStatus === "failed"
                                    ? `External failed${failedTargets ? `: ${failedTargets}` : ""}`
                                    : Services.ThemeService.externalStatus === "unavailable"
                                        ? "External apps: unavailable"
                                        : "External apps: independent"
                    color: Services.ThemeService.externalStatus === "success"
                        ? Services.ThemeService.theme.tokens.success
                        : Services.ThemeService.externalStatus === "partial"
                            ? Services.ThemeService.theme.tokens.warning
                            : Services.ThemeService.externalStatus === "failed"
                                ? Services.ThemeService.theme.tokens.error
                                : Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 11
                }

                Text {
                    text: "Esc to close / Enter to apply"
                    color: Services.ThemeService.theme.tokens.on_surface_variant
                    font.family: Services.ConfigService.config.appearance.monospaceFontFamily
                    font.pixelSize: 11
                }
            }
        }
    }

    Component.onCompleted: themeGrid.forceActiveFocus()
}
