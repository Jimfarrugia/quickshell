import QtQuick
import Quickshell
import "services" as Services

ShellRoot {
    id: root
    property bool requested: false

    function check() {
        if (requested || !Services.ThemeCatalogService.initialized || !Services.ThemeService.initialized) return;
        const hasGruvbox = Services.ThemeCatalogService.catalog.some(theme => theme.id === "gruvbox");
        const rejectedInvalidTheme = Services.ThemeCatalogService.validationErrors.some(error =>
            error.includes("themes/poimandres.json"));
        if (!hasGruvbox || !rejectedInvalidTheme) {
            console.error("THEME_DEGRADATION_TEST_FAILED: valid catalog entries were not isolated from an invalid theme");
            Qt.quit();
            return;
        }
        requested = true;
        Services.ThemeService.requestTheme("gruvbox");
    }

    Connections {
        target: Services.ThemeService
        function onAvailabilityChanged() { root.check(); }
        function onOperationChanged() {
            if (Services.ThemeService.operation === "succeeded") {
                console.log("THEME_DEGRADATION_TEST_PASSED");
                Qt.quit();
            } else if (Services.ThemeService.operation === "failed") {
                console.error("THEME_DEGRADATION_TEST_FAILED: valid remaining theme could not be selected");
                Qt.quit();
            }
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: root.check()
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: {
            console.error("THEME_DEGRADATION_TEST_FAILED: test timed out");
            Qt.quit();
        }
    }

    Component.onCompleted: check()
}
