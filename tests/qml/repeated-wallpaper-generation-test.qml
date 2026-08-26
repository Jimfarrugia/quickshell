import QtQuick
import Quickshell
import Quickshell.Io
import "integrations"
import "services" as Services

ShellRoot {
    id: root

    property int completedGenerations: 0
    property bool started: false
    readonly property string imagePath: Quickshell.env("QE_TEST_WALLPAPER")
        || `${Services.WallpaperService.wallpaperRoot}/themes/poimandres/sample.png`

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
        console.error(`REPEATED_WALLPAPER_GENERATION_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function begin() {
        if (started || !Services.WallpaperService.initialized
                || matugenAdapter.availability !== "available"
                || promotionAdapter.availability !== "available") return;
        started = true;
        const accepted = Services.WallpaperService.requestGeneration(imagePath);
        if (!accepted)
            fail("first generation request was rejected");
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
            if (status !== "succeeded") return;
            root.completedGenerations++;
            if (root.completedGenerations === 1) {
                secondRequest.start();
            } else if (root.completedGenerations === 2) {
                generatedTheme.reload();
                const document = JSON.parse(generatedTheme.text());
                if (document.tokens.primary !== "#a0d0ff")
                    return root.fail(`second generated primary was ${document.tokens.primary}`);
                console.log("REPEATED_WALLPAPER_GENERATION_TEST_PASSED");
                Qt.quit();
            }
        }
    }

    Timer {
        id: secondRequest
        interval: 100
        repeat: false
        onTriggered: {
            const accepted = Services.WallpaperService.requestGeneration(root.imagePath);
            if (!accepted)
                root.fail("second generation request was rejected");
        }
    }

    Timer {
        interval: 15000
        running: true
        onTriggered: root.fail("repeated generation timed out")
    }

    Component.onCompleted: root.begin()
}
