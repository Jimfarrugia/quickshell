import QtQuick
import Quickshell
import Quickshell.Io
import "services" as Services
import "utils/Validation.mjs" as Validation

ShellRoot {
    id: root
    property bool started: false
    property string expectedTheme: ""
    property bool stateProbeReady: false
    property bool testingUnknownTheme: false

    function begin() {
        if (started || !stateProbeReady || !Services.ConfigService.hasLoaded || !Services.ThemeService.initialized
                || Services.ThemeService.catalog.length < 2) return;
        started = true;

        const expectedTokens = Validation.themeTokenNames().sort();
        const emergencyTokens = Object.keys(Services.ThemeService.emergencyTheme.tokens).sort();
        if (JSON.stringify(emergencyTokens) !== JSON.stringify(expectedTokens))
            return fail("emergency theme does not match the approved token contract");

        const confirmedConfig = JSON.stringify(Services.ConfigService.config);
        if (Services.ConfigService.applyText("{") || JSON.stringify(Services.ConfigService.config) !== confirmedConfig) {
            console.error("FOUNDATION_TEST_FAILED: invalid config mutated confirmed state");
            Qt.quit();
            return;
        }

        if (Services.ThemeService.activeThemeId === "gruvbox") {
            if (!stateProbe.loaded) return fail("persisted theme state could not be read");
            try {
                const state = JSON.parse(stateProbe.text());
                if (state.schemaVersion !== 1 || state.activeThemeId !== "gruvbox")
                    return fail("persisted theme state did not contain gruvbox");
            } catch (error) {
                return fail(`persisted theme state was malformed: ${error.message}`);
            }
            console.log("FOUNDATION_PERSISTENCE_TEST_PASSED");
            Qt.quit();
            return;
        }

        const confirmedTheme = Services.ThemeService.activeThemeId;
        testingUnknownTheme = true;
        const acceptedUnknown = Services.ThemeService.requestTheme("not_a_theme");
        testingUnknownTheme = false;
        if (acceptedUnknown || Services.ThemeService.activeThemeId !== confirmedTheme)
            return fail("unknown theme request mutated confirmed state");

        expectedTheme = "gruvbox";
        if (!Services.ThemeService.requestTheme(expectedTheme)) {
            fail("valid theme request was rejected");
        }
    }

    function fail(message) {
        console.error(`FOUNDATION_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    FileView {
        id: stateProbe
        path: Services.PathsService.activeThemeState
        blockLoading: true
        printErrors: false
        onLoaded: {
            root.stateProbeReady = true;
            root.begin();
        }
        onLoadFailed: {
            root.stateProbeReady = true;
            root.begin();
        }
    }

    Connections {
        target: Services.ConfigService
        function onHasLoadedChanged() { root.begin(); }
    }

    Connections {
        target: Services.ThemeService
        function onCatalogChanged() { root.begin(); }
        function onInitializedChanged() { root.begin(); }
        function onOperationChanged() {
            if (Services.ThemeService.operation === "succeeded") {
                if (Services.ThemeService.activeThemeId !== root.expectedTheme) {
                    console.error("FOUNDATION_TEST_FAILED: persisted theme was not published");
                    Qt.quit();
                    return;
                }
                console.log("FOUNDATION_THEME_SEEDED");
                Qt.quit();
            } else if (Services.ThemeService.operation === "failed" && !root.testingUnknownTheme) {
                console.error("FOUNDATION_TEST_FAILED: theme persistence failed");
                Qt.quit();
            }
        }
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: {
            console.error("FOUNDATION_TEST_FAILED: service test timed out");
            Qt.quit();
        }
    }

    Component.onCompleted: begin()
}
