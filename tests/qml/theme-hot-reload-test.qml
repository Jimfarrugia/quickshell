import QtQuick
import Quickshell
import Quickshell.Io
import "services" as Services

ShellRoot {
    id: root

    property int stage: 0
    property string originalText: ""
    property string modifiedText: ""
    property string originalPrimary: ""
    readonly property string modifiedPrimary: "#a8ffea"
    readonly property bool isolatedTest: Quickshell.env("QE_TEST_ISOLATED") === "1"
    readonly property string addedPath: Services.PathsService.shellPath("themes/added_test.json")
    readonly property string invalidPath: Services.PathsService.shellPath("themes/invalid_test.json")
    readonly property string duplicatePath: Services.PathsService.shellPath("themes/duplicate_test.json")
    readonly property string backupPath: Services.PathsService.shellPath(".poimandres-backup.json")

    function fail(message) {
        console.error(`THEME_HOT_RELOAD_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function scheduleEvaluate() {
        Qt.callLater(root.evaluate);
    }

    function begin() {
        if (!isolatedTest) return;
        if (stage !== 0 || !themeEditor.loaded || !Services.ThemeService.initialized) return;
        if (Services.ThemeService.activeThemeId !== "poimandres")
            return fail(`expected poimandres, got ${Services.ThemeService.activeThemeId}`);

        originalText = themeEditor.text();
        const modified = JSON.parse(originalText);
        originalPrimary = Services.ThemeService.theme.tokens.primary;
        modified.tokens.primary = modifiedPrimary;
        modifiedText = JSON.stringify(modified, null, 2) + "\n";
        stage = 1;
        themeEditor.setText(modifiedText);
    }

    function catalogContains(id) {
        return Services.ThemeService.findTheme(id) !== null;
    }

    function documentText(id, name, valid) {
        const document = JSON.parse(originalText);
        document.id = id;
        document.name = name;
        if (!valid) delete document.tokens.primary;
        return JSON.stringify(document, null, 2) + "\n";
    }

    function runFileCommand(command) {
        if (fileCommand.running) return fail("file command was already running");
        fileCommand.command = command;
        fileCommand.running = true;
    }

    function removeFiles(paths) {
        runFileCommand(["rm", "--"].concat(paths));
    }

    function evaluate() {
        if (stage === 1 && Services.ThemeService.theme.tokens.primary === modifiedPrimary) {
            if (Services.ThemeService.activeThemeId !== "poimandres")
                return fail("valid edit changed the active theme ID");
            const invalid = JSON.parse(modifiedText);
            delete invalid.tokens.primary;
            stage = 2;
            themeEditor.setText(JSON.stringify(invalid, null, 2) + "\n");
        } else if (stage === 2 && Services.ThemeService.validationErrors.length > 0) {
            if (Services.ThemeService.theme.tokens.primary !== modifiedPrimary)
                return fail("invalid edit replaced the last-known-good theme");
            stage = 3;
            themeEditor.setText(originalText);
        } else if (stage === 3 && Services.ThemeService.validationErrors.length === 0
                   && Services.ThemeService.theme.tokens.primary === originalPrimary) {
            stage = 4;
            addedWriter.setText(documentText("added_test", "Added Test", true));
        } else if (stage === 4 && catalogContains("added_test")) {
            if (Services.ThemeService.catalog.length !== 3)
                return fail("valid catalog addition produced the wrong catalog size");
            stage = 5;
            invalidWriter.setText(documentText("invalid_test", "Invalid Test", false));
        } else if (stage === 5 && Services.ThemeService.validationErrors.some(error => error.includes("themes/invalid_test.json"))) {
            if (catalogContains("invalid_test"))
                return fail("invalid theme entered the catalog");
            stage = 6;
            duplicateWriter.setText(documentText("gruvbox", "Duplicate Gruvbox", true));
        } else if (stage === 6 && Services.ThemeService.validationErrors.some(error => error.includes("themes/duplicate_test.json") && error.includes("duplicate theme ID"))) {
            if (catalogContains("gruvbox"))
                return fail("a duplicated theme ID remained in the catalog");
            stage = 7;
            removeFiles([addedPath, invalidPath, duplicatePath]);
        } else if (stage === 7 && !fileCommand.running
                   && Services.ThemeService.catalog.length === 2
                   && Services.ThemeService.validationErrors.length === 0
                   && catalogContains("poimandres") && catalogContains("gruvbox")) {
            stage = 8;
            removeFiles([themeEditor.path]);
        } else if (stage === 8 && !fileCommand.running
                   && Services.ThemeService.activeSourceMissing
                   && Services.ThemeService.freshness === "stale") {
            if (Services.ThemeService.activeThemeId !== "poimandres"
                    || Services.ThemeService.theme.tokens.primary !== originalPrimary)
                return fail("active source removal did not retain the last-known-good theme");
            stage = 9;
            runFileCommand(["cp", "--", backupPath, themeEditor.path]);
        } else if (stage === 9 && !Services.ThemeService.activeSourceMissing
                   && Services.ThemeService.freshness === "current"
                   && catalogContains("poimandres")
                   && Services.ThemeService.theme.tokens.primary === originalPrimary) {
            stage = 10;
            console.log("THEME_HOT_RELOAD_AND_CATALOG_TEST_PASSED");
            Qt.quit();
        }
    }

    FileView {
        id: themeEditor
        path: Services.PathsService.shellPath("themes/poimandres.json")
        blockLoading: true
        atomicWrites: true
        printErrors: false
        onLoaded: root.begin()
        onSaveFailed: error => root.fail(`theme fixture write failed: ${error}`)
    }

    FileView {
        id: addedWriter
        path: root.addedPath
        atomicWrites: true
        printErrors: false
        onSaveFailed: error => root.fail(`added theme write failed: ${error}`)
    }

    FileView {
        id: invalidWriter
        path: root.invalidPath
        atomicWrites: true
        printErrors: false
        onSaveFailed: error => root.fail(`invalid theme write failed: ${error}`)
    }

    FileView {
        id: duplicateWriter
        path: root.duplicatePath
        atomicWrites: true
        printErrors: false
        onSaveFailed: error => root.fail(`duplicate theme write failed: ${error}`)
    }

    Process {
        id: fileCommand
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.fail(`file command failed (${exitCode}, ${exitStatus}): ${JSON.stringify(command)}`);
            else
                Qt.callLater(root.evaluate);
        }
    }

    Connections {
        target: Services.ThemeService
        function onInitializedChanged() { root.begin(); }
        function onThemeChanged() { root.scheduleEvaluate(); }
        function onValidationErrorsChanged() { root.scheduleEvaluate(); }
        function onCatalogChanged() { root.scheduleEvaluate(); }
        function onFreshnessChanged() { root.scheduleEvaluate(); }
    }

    Timer {
        interval: 15000
        running: true
        onTriggered: root.fail(`timed out at stage ${root.stage}`)
    }

    Component.onCompleted: {
        if (!isolatedTest)
            return fail("must be run through its isolating helper");
        begin();
    }
}
