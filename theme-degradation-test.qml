import QtQuick
import Quickshell
import "services" as Services

ShellRoot {
    id: root
    property bool requested: false

    function check() {
        if (requested || Services.ThemeService.availability === "unknown") return;
        if (Services.ThemeService.availability !== "degraded" || Services.ThemeService.catalog.length !== 1
                || Services.ThemeService.catalog[0].id !== "gruvbox") {
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
        interval: 4000
        running: true
        onTriggered: {
            console.error("THEME_DEGRADATION_TEST_FAILED: test timed out");
            Qt.quit();
        }
    }

    Component.onCompleted: check()
}
