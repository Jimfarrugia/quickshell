import QtQuick
import Quickshell
import Quickshell.Io
import "integrations"
import "services" as Services

ShellRoot {
    id: root

    readonly property string imagePath: `${Services.WallpaperService.wallpaperRoot}/themes/poimandres/sample.png`
    readonly property string sentinelId: "last_known_good"
    property bool requested: false
    property bool seeded: false

    function sentinelText() {
        return JSON.stringify({
            schemaVersion: 1,
            id: root.sentinelId,
            name: "Last Known Good",
            variant: "dark",
            palette: { black: "#000000" },
            tokens: Services.ThemeService.emergencyTheme.tokens
        }, null, 2) + "\n";
    }

    MatugenAdapter {
        id: matugenAdapter
        executable: Quickshell.env("QE_MATUGEN")
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
        property: "promotionAdapter"
        value: promotionAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }

    FileView {
        id: existingTheme
        path: Services.PathsService.generatedThemePath
        blockLoading: true
        atomicWrites: true
        printErrors: false

        function seed() {
            if (root.seeded) return;
            if (loaded && text() === root.sentinelText()) {
                root.seeded = true;
                root.begin();
            } else {
                setText(root.sentinelText());
            }
        }

        onLoaded: seed()
        onLoadFailed: seed()
        onSaved: {
            root.seeded = true;
            root.begin();
        }
    }

    function begin() {
        if (requested || !seeded || !Services.WallpaperService.initialized
                || matugenAdapter.availability !== "available"
                || promotionAdapter.availability !== "available") return;
        requested = true;
        if (!Services.WallpaperService.requestGeneration(imagePath))
            fail("wallpaper service rejected the failure test request");
    }

    function fail(message) {
        console.error(`WALLPAPER_GENERATION_FAILURE_TEST_FAILED: ${message}`);
        Qt.quit();
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
            if (Services.WallpaperService.generationStatus !== "failed") return;
            let retained;
            try {
                retained = JSON.parse(existingTheme.text()).id === root.sentinelId;
            } catch (error) {
                retained = false;
            }
            if (!retained)
                return root.fail("failed generation replaced the last-known-good artifact");
            console.log("WALLPAPER_GENERATION_FAILURE_TEST_PASSED");
            Qt.quit();
        }
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail("wallpaper generation failure test timed out")
    }

    Component.onCompleted: existingTheme.seed()
}
