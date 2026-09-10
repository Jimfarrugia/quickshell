import QtQuick
import Quickshell
import Quickshell as QS
import "services" as Services

ShellRoot {
    id: root

    QS.LazyLoader {
        id: controlLoader
        active: Services.SurfaceService.controlCenterVisible
        source: "modules/controlcenter/ControlCenter.qml"
    }

    function fail(message) {
        console.error(`CONTROL_CENTER_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function check() {
        const control = controlLoader.item;
        if (!control) return;
        if (control.surfaceWidth <= 0 || control.surfaceHeight <= 0) return;
        if (Services.TimeService.timeText.length === 0
                || Services.TimeService.longDateText.length === 0)
            return fail("control center clock did not receive time and long date");
        if (Services.ThemeService.catalog.length === 0
                || control.themeDropdown.currentText.length === 0)
            return;
        if (control.themeDropdown.model.length !== Services.ThemeService.catalog.length)
            return fail("theme dropdown did not bind to the theme catalog");
        if (control.statusFor("unavailable", "unknown", null) !== "unavailable"
                || control.statusFor("available", "stale", null) !== "stale")
            return fail("control center status projection lost degraded states");

        control.requestDefaults("capture");
        if (!control.confirmationVisible)
            return fail("capture confirmation did not open");
        control.dismissFromEscape();
        if (control.confirmationVisible)
            return fail("Escape did not dismiss the confirmation overlay");
        control.dismissFromOutside();
        if (controlLoader.item !== null)
            return fail("control center did not unload after close");

        console.log("CONTROL_CENTER_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (!Services.SurfaceService.controlCenterVisible)
                Services.SurfaceService.openControlCenter();
            else root.check();
        }
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail("control center test timed out")
    }
}
