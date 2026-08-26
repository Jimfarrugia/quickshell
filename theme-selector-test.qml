import QtQuick
import Quickshell
import "modules/theme"
import "services" as Services

ShellRoot {
    id: root

    property bool requested: false
    property string expectedThemeId: ""

    function begin() {
        if (requested || !Services.ThemeService.initialized || Services.ThemeService.catalog.length < 2)
            return;
        expectedThemeId = Services.ThemeService.activeThemeId === "poimandres" ? "gruvbox" : "poimandres";
        if (selector.applyTheme(Services.ThemeService.activeThemeId))
            return fail("selector accepted the already-active theme");
        requested = true;
        if (!selector.applyTheme(expectedThemeId))
            fail("selector rejected a valid catalog theme");
    }

    function fail(message) {
        console.error(`THEME_SELECTOR_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    ThemeSelector { id: selector }

    Connections {
        target: Services.ThemeService
        function onInitializedChanged() { root.begin(); }
        function onCatalogChanged() { root.begin(); }
        function onOperationChanged() {
            if (Services.ThemeService.operation === "succeeded") {
                if (Services.ThemeService.activeThemeId !== root.expectedThemeId)
                    return root.fail("selector did not publish the requested active theme");
                const candidate = Services.ThemeService.findTheme(root.expectedThemeId);
                if (candidate === null || candidate.tokens.primary !== Services.ThemeService.theme.tokens.primary)
                    return root.fail("selector did not publish the resolved catalog candidate");
                console.log("THEME_SELECTOR_TEST_PASSED");
                Qt.quit();
            } else if (Services.ThemeService.operation === "failed") {
                root.fail("selector theme request failed");
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail("selector test timed out")
    }

    Component.onCompleted: begin()
}
