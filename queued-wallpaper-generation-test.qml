import QtQuick
import Quickshell
import Quickshell.Io
import "integrations"
import "services" as Services

ShellRoot {
    id: root

    property bool started: false
    property int succeededCount: 0
    readonly property string firstImage: Quickshell.env("QE_TEST_WALLPAPER_A")
    readonly property string secondImage: Quickshell.env("QE_TEST_WALLPAPER_B")

    MatugenAdapter {
        id: matugenAdapter
        executable: Quickshell.env("QE_MATUGEN")
    }

    WallpaperPromotionAdapter { id: promotionAdapter }

    FileView {
        id: generatedTheme
        path: Services.PathsService.generatedThemePath
        blockLoading: true
        blockAllReads: true
        printErrors: false
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

    function fail(message) {
        console.error(`QUEUED_WALLPAPER_GENERATION_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function begin() {
        if (started || !Services.WallpaperService.initialized
                || matugenAdapter.availability !== "available"
                || promotionAdapter.availability !== "available") return;
        started = true;
        if (!Services.WallpaperService.requestGeneration(firstImage))
            return fail("first generation request was rejected");
        if (!Services.WallpaperService.requestGeneration(secondImage))
            return fail("queued generation request was dropped while one was pending");
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
            if (Services.WallpaperService.generationStatus === "failed")
                return root.fail(Services.WallpaperService.lastError);
            if (Services.WallpaperService.generationStatus !== "succeeded") return;
            root.succeededCount++;
            if (root.succeededCount === 2) {
                generatedTheme.reload();
                const document = JSON.parse(generatedTheme.text());
                if (document.tokens.primary !== "#a0d0ff")
                    return root.fail(`final generated primary was ${document.tokens.primary}`);
                console.log("QUEUED_WALLPAPER_GENERATION_TEST_PASSED");
                Qt.quit();
            }
        }
    }

    Timer {
        interval: 15000
        running: true
        onTriggered: root.fail("queued generation timed out")
    }

    Component.onCompleted: root.begin()
}