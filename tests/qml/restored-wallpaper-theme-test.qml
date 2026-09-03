import QtQuick
import Quickshell
import "services" as Services

ShellRoot {
    id: root

    property bool started: false

    Scope {
        id: failingMatugen
        property string availability: "available"
        readonly property bool running: false
        signal finished(var result)

        function generate(imagePath, variant, operationId) {
            Qt.callLater(() => finished({
                operationId,
                success: false,
                theme: null,
                colors: null,
                error: "wallpaper source is unavailable",
                stderr: "",
                timedOut: false
            }));
            return true;
        }
    }

    Scope {
        id: fakePromotion
        property string availability: "available"
        readonly property bool running: false
        signal finished(var result)
        function promote(stagePath, destinationPath, operationId) { return true; }
    }

    Scope {
        id: fakeExternal
        property string availability: "available"
        readonly property bool running: false
        property var lastState: null
        property string requestedTheme: ""
        property bool skippedGtk: false
        signal finished(var result)

        function start(themeId, operationId, skipGtk) {
            requestedTheme = themeId;
            skippedGtk = skipGtk === true;
            Qt.callLater(() => finished({
                operationId,
                contractValid: true,
                status: "success",
                persisted: true,
                requestedThemeId: themeId,
                targets: [],
                error: null,
                timedOut: false,
                stderr: ""
            }));
            return true;
        }
    }

    Binding {
        target: Services.ThemeService
        property: "externalAdapter"
        value: fakeExternal
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: Services.WallpaperService
        property: "matugenAdapter"
        value: failingMatugen
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: Services.WallpaperService
        property: "promotionAdapter"
        value: fakePromotion
        restoreMode: Binding.RestoreBindingOrValue
    }

    function fail(message) {
        console.error(`RESTORED_WALLPAPER_THEME_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function begin() {
        if (started || !Services.ThemeService.initialized
                || !Services.ThemeCatalogService.initialized
                || !Services.WallpaperService.initialized) return;
        const restored = Services.ThemeService.findTheme("wallpaper");
        if (restored === null)
            return fail("restored wallpaper theme was not catalogued");
        started = true;
        // Exercise selection with an existing wallpaper source that fails
        // asynchronously; the last promoted external slots must still apply.
        Services.WallpaperService.selectedPath = Services.PathsService.defaultWallpaperImage;
        if (!Services.ThemeService.requestTheme("wallpaper"))
            fail("restored wallpaper theme was not selectable");
    }

    Connections {
        target: Services.ThemeService
        function onInitializedChanged() { root.begin(); }
        function onCatalogChanged() { root.begin(); }
        function onExternalOperationChanged() {
            if (Services.ThemeService.externalOperation !== "succeeded") return;
            if (Services.ThemeService.activeThemeId !== "wallpaper")
                return root.fail("wallpaper did not become active");
            if (fakeExternal.requestedTheme !== "wallpaper" || !fakeExternal.skippedGtk)
                return root.fail("restored external wallpaper theme was not dispatched correctly");
            console.log("RESTORED_WALLPAPER_THEME_TEST_PASSED");
            Qt.quit();
        }
    }

    Connections {
        target: Services.ThemeCatalogService
        function onInitializedChanged() { root.begin(); }
    }

    Connections {
        target: Services.WallpaperService
        function onInitializedChanged() { root.begin(); }
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail("restored wallpaper theme test timed out")
    }

    Component.onCompleted: begin()
}
