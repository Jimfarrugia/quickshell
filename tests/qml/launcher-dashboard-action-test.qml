import QtQuick
import Quickshell
import "services" as Services

ShellRoot {
    id: root
    property int attempts: 0
    QtObject {
        id: controller
        property bool visible: false
        property string activeId: ""
        property var sourceScreen: null
        function toggle(id, screen, side) {
            if (visible && activeId === id) {
                visible = false;
                activeId = "";
            } else {
                visible = true;
                activeId = id;
                sourceScreen = screen;
            }
        }
    }

    function fail(message) {
        console.error(`LAUNCHER_DASHBOARD_ACTION_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function check() {
        Services.SurfaceService.dashboardController = controller;
        Services.LauncherService.query = "audio";
        Services.LauncherService.refresh(false);
        if (!Services.LauncherService.results.length) {
            if (++attempts >= 20) fail("curated audio action was not discoverable");
            return;
        }
        const action = Services.LauncherService.results[0];
        if (action.id !== "qe-dashboard-audio" || action.actionId !== "audio")
            return fail("audio action metadata was not stable");
        if (!Services.LauncherService.launchEntry(action))
            return fail("audio action activation failed");
        if (!controller.visible || controller.activeId !== "audio"
                || controller.sourceScreen !== Services.SurfaceService.activeScreen())
            return fail("audio dashboard was not toggled through the surface contract");
        console.log("LAUNCHER_DASHBOARD_ACTION_TEST_PASSED");
        Qt.quit();
    }

    Timer { interval: 100; repeat: true; running: true; onTriggered: root.check() }
}
