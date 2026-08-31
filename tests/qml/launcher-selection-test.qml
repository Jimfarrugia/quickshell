import QtQuick
import Quickshell
import "services" as Services

ShellRoot {
    id: root
    property int attempts: 0

    function fail(message) {
        console.error(`LAUNCHER_SELECTION_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function check() {
        Services.LauncherService.usage = {};
        Services.LauncherService.query = "";
        Services.LauncherService.refresh(false);
        if (Services.LauncherService.results.length < 2) {
            if (++attempts >= 20) fail("desktop entry catalog did not load");
            return;
        }

        Services.LauncherService.selectedIndex = 1;
        Services.LauncherService.selectionExplicit = false;
        Services.LauncherService.refresh();
        if (Services.LauncherService.selectedIndex !== 0)
            return fail("provisional selection survived a startup refresh");

        Services.LauncherService.move(1);
        const selectedId = Services.LauncherService.results[Services.LauncherService.selectedIndex].id;
        Services.LauncherService.refresh();
        if (!Services.LauncherService.selectionExplicit
                || Services.LauncherService.results[Services.LauncherService.selectedIndex].id !== selectedId)
            return fail("explicit selection was not retained");

        console.log("LAUNCHER_SELECTION_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        interval: 100
        repeat: true
        running: true
        onTriggered: root.check()
    }
}
