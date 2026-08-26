import QtQuick
import QtQuick.Window
import QtQml
import Quickshell
import "integrations"
import "services" as Services

ShellRoot {
    id: root

    property bool started: false
    property bool themeSelected: false
    readonly property string imagePath: Quickshell.env("QE_TEST_WALLPAPER")
        || `${Services.WallpaperService.wallpaperRoot}/themes/poimandres/sample.png`

    Scope {
        id: fakeExternalTheme
        property string availability: "available"
        readonly property bool running: false
        property var lastState: null
        property string requestedThemeId: ""
        property string requestedOperationId: ""
        property bool skipGtkApplied: false
        signal finished(var result)

        function start(themeId, operationId, skipGtk) {
            if (running || availability !== "available") return false;
            requestedThemeId = themeId;
            requestedOperationId = operationId;
            skipGtkApplied = skipGtk === true;
            Qt.callLater(() => finished({
                operationId: requestedOperationId,
                contractValid: true,
                status: "success",
                persisted: true,
                requestedThemeId: themeId,
                targets: [{ target: "kitty", status: "applied", exitCode: 0, reason: null, detail: null }],
                error: null,
                timedOut: false,
                stderr: ""
            }));
            return true;
        }
    }

    MatugenAdapter {
        id: matugenAdapter
        executable: Quickshell.env("QE_MATUGEN")
    }

    WallpaperPromotionAdapter { id: promotionAdapter }
    WallpaperExternalThemeAdapter { id: externalPromotionAdapter }

    Scope {
        id: fakeExternalWallpaper
        property string availability: "available"
        readonly property bool running: false
        signal finished(var result)

        function apply(specPath, operationId) {
            Qt.callLater(() => finished({
                operationId,
                contractValid: true,
                success: true,
                status: "succeeded",
                results: [],
                failedTargets: [],
                skippedTargets: 0,
                error: ""
            }));
            return true;
        }
    }

    Binding {
        target: Services.WallpaperService
        property: "matugenAdapter"
        value: matugenAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }
    Binding {
        target: Services.WallpaperService
        property: "promotionAdapter"
        value: promotionAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }
    Binding {
        target: Services.WallpaperService
        property: "externalThemeAdapter"
        value: fakeExternalWallpaper
        restoreMode: Binding.RestoreBindingOrValue
    }
    Binding {
        target: Services.ThemeService
        property: "externalAdapter"
        value: fakeExternalTheme
        restoreMode: Binding.RestoreBindingOrValue
    }

    function fail(message) {
        console.error(`WALLPAPER_THEME_SELECT_EXTERNAL_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function begin() {
        if (started || !Services.WallpaperService.initialized
                || !Services.ThemeService.initialized
                || !Services.ThemeCatalogService.initialized
                || matugenAdapter.availability !== "available"
                || promotionAdapter.availability !== "available") return;
        started = true;
        if (!Services.WallpaperService.requestGeneration(imagePath))
            fail("initial wallpaper generation was rejected");
    }

    function selectWallpaperTheme() {
        if (Services.ThemeService.findTheme("wallpaper") === null) return;
        if (!Services.ThemeService.requestTheme("wallpaper"))
            fail("selecting the wallpaper theme was rejected");
        themeSelected = true;
    }

    Connections {
        target: matugenAdapter
        function onAvailabilityChanged() { root.begin(); }
    }
    Connections {
        target: promotionAdapter
        function onAvailabilityChanged() { root.begin(); }
    }
    Connections {
        target: Services.WallpaperService
        function onInitializedChanged() { root.begin(); }
        function onGenerationStatusChanged() {
            const status = Services.WallpaperService.generationStatus;
            if (status === "failed") return root.fail(Services.WallpaperService.lastError);
            if (status === "succeeded" && root.started && !root.themeSelected)
                Qt.callLater(root.selectWallpaperTheme);
        }
    }
    function verify() {
        if (!Services.WallpaperService.wallpaperDirectory.endsWith("/themes/wallpaper"))
            return `wallpaperDirectory was ${Services.WallpaperService.wallpaperDirectory}`;
        return null;
    }

    Connections {
        target: Services.ThemeService
        function onInitializedChanged() { root.begin(); }
        function onActiveThemeIdChanged() {
            if (Services.ThemeService.activeThemeId !== "wallpaper") return;
            if (fakeExternalTheme.requestedThemeId !== "wallpaper") return;
            if (!fakeExternalTheme.skipGtkApplied) return root.fail("wallpaper external apply did not skip GTK");
            if (Services.ThemeService.externalOperation !== "succeeded")
                return root.fail(`external operation ended as ${Services.ThemeService.externalOperation}`);
            const error = root.verify();
            if (error) return root.fail(error);
            console.log("WALLPAPER_THEME_SELECT_EXTERNAL_TEST_PASSED");
            Qt.quit();
        }
        function onExternalOperationChanged() {
            if (Services.ThemeService.externalOperation !== "succeeded") return;
            if (Services.ThemeService.activeThemeId !== "wallpaper") return;
            if (fakeExternalTheme.requestedThemeId !== "wallpaper") return;
            if (!fakeExternalTheme.skipGtkApplied) return root.fail("wallpaper external apply did not skip GTK");
            const error = root.verify();
            if (error) return root.fail(error);
            console.log("WALLPAPER_THEME_SELECT_EXTERNAL_TEST_PASSED");
            Qt.quit();
        }
    }
    Connections {
        target: Services.ThemeCatalogService
        function onInitializedChanged() { root.begin(); }
        function onCatalogChanged() {
            if (Services.WallpaperService.generationStatus === "succeeded"
                    && root.started && !root.themeSelected)
                Qt.callLater(root.selectWallpaperTheme);
        }
    }

    Timer {
        interval: 20
        repeat: true
        running: root.started && !root.themeSelected
            && Services.WallpaperService.generationStatus === "succeeded"
        onTriggered: root.selectWallpaperTheme()
    }

    Timer {
        interval: 15000
        running: true
        onTriggered: root.fail("wallpaper theme select flows timed out")
    }

    Component.onCompleted: root.begin()
}
