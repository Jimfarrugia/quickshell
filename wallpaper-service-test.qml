import QtQuick
import QtQml
import Quickshell
import "integrations"
import "services" as Services

ShellRoot {
    id: root

    property bool requested: false
    property bool generated: false
    property bool cached: false
    readonly property string imagePath: Quickshell.env("QE_TEST_WALLPAPER")
        || `${Services.WallpaperService.wallpaperRoot}/themes/poimandres/sample.png`

    MatugenAdapter {
        id: matugenAdapter
        executable: Quickshell.env("QE_MATUGEN")
    }

    WallpaperCacheAdapter {
        id: cacheAdapter
    }

    WallpaperPromotionAdapter {
        id: promotionAdapter
    }

    Binding {
        target: Services.WallpaperService
        property: "matugenAdapter"
        value: matugenAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: Services.WallpaperService
        property: "cacheAdapter"
        value: cacheAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: Services.WallpaperService
        property: "promotionAdapter"
        value: promotionAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }

    function begin() {
        if (requested || !Services.WallpaperService.initialized
                || matugenAdapter.availability !== "available") return;
        requested = true;
        if (!Services.WallpaperService.requestGeneration(root.imagePath))
            fail("wallpaper service rejected a valid generation request");
    }

    function fail(message) {
        console.error(`WALLPAPER_SERVICE_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    Connections {
        target: matugenAdapter
        function onAvailabilityChanged() { root.begin(); }
    }

    Connections {
        target: Services.WallpaperService
        function onInitializedChanged() { root.begin(); }
        function onCacheStatusChanged() {
            if (Services.WallpaperService.cacheStatus === "failed")
                return root.fail(`cache failed: ${Services.WallpaperService.lastError}`);
            if (Services.WallpaperService.cacheStatus === "succeeded") {
                root.finishIfReady();
            }
        }
        function onCacheUpdated() {
            root.cached = Services.WallpaperService.catalogModel.count > 0;
            root.finishIfReady();
        }
        function onGenerationStatusChanged() {
            if (Services.WallpaperService.generationStatus === "failed")
                root.fail(Services.WallpaperService.lastError);
            if (Services.WallpaperService.generationStatus === "succeeded") {
                root.generated = true;
                root.finishIfReady();
            }
        }
    }

    function finishIfReady() {
        if (!generated || !cached) return;
        console.log("WALLPAPER_SERVICE_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        interval: 150000
        running: true
        onTriggered: root.fail("wallpaper service test timed out")
    }

    Component.onCompleted: root.begin()
}
