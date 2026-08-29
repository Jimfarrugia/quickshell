import QtQuick
import Quickshell
import "services" as Services
import "modules/bar" as Bar
import "fixtures/qml" as Fixtures

ShellRoot {
    id: root
    property bool done: false
    Fixtures.FakePowerIntegration { id: fakePower }
    Bar.BatteryModule { id: batteryModule; visible: false }

    function fail(message) {
        if (done) return;
        done = true;
        console.error(`OSD_SERVICE_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    Component.onCompleted: {
        Services.OSDService.clear();
        Services.OSDService.showItem({ title: "Volume", detail: "40%", value: 40, replacementKey: "audio" });
        if (!Services.OSDService.activeItem || Services.OSDService.activeItem.detail !== "40%")
            return fail("initial OSD was not presented");
        Services.OSDService.showItem({ title: "Volume", detail: "45%", value: 45, state: "pending", replacementKey: "audio" });
        if (Services.OSDService.activeItem.detail !== "45%" || Services.OSDService.activeItem.state !== "pending")
            return fail("replacement key did not update active OSD");
        Services.OSDService.showItem({ title: "Network", detail: "Online", priority: 1, replacementKey: "network" });
        Services.OSDService.showItem({ title: "Battery", detail: "15%", priority: 3, replacementKey: "battery" });
        if (Services.OSDService.queue.length !== 2 || Services.OSDService.queue[0].title !== "Battery")
            return fail("priority queue was not ordered or bounded");

        fakePower.present = true;
        fakePower.availability = "available";
        fakePower.percentage = 86;
        fakePower.charging = true;
        fakePower.fullyCharged = true;
        Services.PowerService.integration = fakePower;
        Services.OSDService.primed = true;
        Services.OSDService.lastBatteryState = "";
        Services.OSDService.clear();
        Services.OSDService.batteryChanged();
        if (!Services.OSDService.activeItem || Services.OSDService.activeItem.detail !== "Charging")
            return fail("non-full charging battery was reported as fully charged");
        if (batteryModule.textColor.toString() !== Services.ThemeService.theme.tokens.on_surface_disabled.toString())
            return fail("charging battery text did not use the standard muted text color");

        fakePower.charging = false;
        Services.OSDService.lastBatteryState = "";
        Services.OSDService.batteryChanged();
        if (!Services.OSDService.activeItem || Services.OSDService.activeItem.detail !== "86% remaining")
            return fail("non-full discharging battery was reported as fully charged");

        Services.OSDService.clear();
        if (Services.OSDService.activeItem !== null || Services.OSDService.queue.length !== 0)
            return fail("clear did not release OSD state");
        done = true;
        console.log("OSD_SERVICE_TEST_PASSED");
        Qt.quit();
    }
}
