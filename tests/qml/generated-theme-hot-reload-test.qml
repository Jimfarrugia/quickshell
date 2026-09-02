import QtQuick
import Quickshell
import Quickshell.Io
import "services" as Services

ShellRoot {
    id: root

    property int stage: 0
    property string sourceText: ""
    readonly property string firstPrimary: "#123456"
    readonly property string secondPrimary: "#654321"
    readonly property string sourcePath: Services.PathsService.shellPath("themes/poimandres.json")
    readonly property bool isolatedTest: Quickshell.env("QE_TEST_ISOLATED") === "1"

    function fail(message) {
        console.error(`GENERATED_THEME_HOT_RELOAD_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function wallpaperDocument(primary) {
        const document = JSON.parse(sourceText);
        document.id = "wallpaper";
        document.name = "Wallpaper";
        document.tokens.primary = primary;
        return JSON.stringify(document, null, 2) + "\n";
    }

    function evaluate() {
        const generated = Services.ThemeService.findTheme("wallpaper");
        if (stage === 1 && generated !== null) {
            if (generated.tokens.primary !== firstPrimary)
                return fail(`first generated primary was ${generated.tokens.primary}`);
            stage = 2;
            generatedWriter.setText(wallpaperDocument(secondPrimary));
        } else if (stage === 2 && generated !== null
                   && generated.tokens.primary === secondPrimary) {
            console.log("GENERATED_THEME_HOT_RELOAD_TEST_PASSED");
            Qt.quit();
        }
    }

    FileView {
        id: sourceFile
        path: root.sourcePath
        blockLoading: true
        printErrors: false
        onLoaded: {
            if (!root.isolatedTest) return;
            root.sourceText = text();
            if (Services.ThemeCatalogService.initialized && root.stage === 0) {
                root.stage = 1;
                generatedWriter.setText(root.wallpaperDocument(root.firstPrimary));
            }
        }
        onLoadFailed: root.fail("source theme could not be read")
    }

    FileView {
        id: generatedWriter
        path: Services.PathsService.generatedThemePath
        atomicWrites: true
        printErrors: false
        onSaveFailed: error => root.fail(`generated theme write failed: ${error}`)
    }

    Connections {
        target: Services.ThemeCatalogService
        function onInitializedChanged() {
            if (!root.isolatedTest) return;
            if (Services.ThemeCatalogService.initialized && sourceFile.loaded
                    && root.stage === 0) {
                root.stage = 1;
                generatedWriter.setText(root.wallpaperDocument(root.firstPrimary));
            }
        }
        function onCatalogChanged() {
            if (root.isolatedTest) Qt.callLater(root.evaluate);
        }
    }

    Connections {
        target: Services.ThemeService
        function onCatalogChanged() {
            if (root.isolatedTest) Qt.callLater(root.evaluate);
        }
    }

    Timer {
        interval: 15000
        running: true
        onTriggered: root.fail(`timed out at stage ${root.stage}`)
    }

    Component.onCompleted: {
        if (!isolatedTest)
            return fail("must be run through its isolating helper");
        if (Services.ThemeCatalogService.initialized && sourceFile.loaded) {
            stage = 1;
            generatedWriter.setText(wallpaperDocument(firstPrimary));
        }
    }
}
