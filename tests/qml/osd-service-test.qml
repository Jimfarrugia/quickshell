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
        fakePower.timeToFullSeconds = 5400;
        Services.PowerService.integration = fakePower;
        Services.OSDService.primed = true;
        Services.OSDService.lastBatteryState = "";
        Services.OSDService.clear();
        Services.OSDService.batteryChanged();
        if (!Services.OSDService.activeItem || Services.OSDService.activeItem.title !== "Charging"
                || Services.OSDService.activeItem.detail !== "86% remaining (1h 30m)")
            return fail("charging battery popup did not include the expected title and estimate");
        if (batteryModule.textColor.toString() !== Services.ThemeService.theme.tokens.on_surface_disabled.toString())
            return fail("charging battery text did not use the standard muted text color");

        fakePower.charging = false;
        fakePower.timeToEmptySeconds = 16200;
        Services.OSDService.lastBatteryState = "";
        Services.OSDService.batteryChanged();
        if (!Services.OSDService.activeItem || Services.OSDService.activeItem.title !== "Discharging"
                || Services.OSDService.activeItem.detail !== "86% remaining (4h 30m)")
            return fail("discharging battery popup did not include the expected title and estimate");

        fakePower.percentage = 100;
        fakePower.timeToEmptySeconds = 0;
        fakePower.fullyCharged = false;
        Services.OSDService.lastBatteryState = "";
        Services.OSDService.batteryChanged();
        if (!Services.OSDService.activeItem || Services.OSDService.activeItem.title !== "Discharging"
                || Services.OSDService.activeItem.detail !== "100%")
            return fail("discharging battery popup did not omit an unavailable estimate");

        fakePower.fullyCharged = true;
        Services.OSDService.lastBatteryState = "";
        Services.OSDService.batteryChanged();
        if (!Services.OSDService.activeItem || Services.OSDService.activeItem.title !== "Charging"
                || Services.OSDService.activeItem.detail !== "100% remaining")
            return fail("fully charged battery popup did not use charging semantics");

        fakePower.percentage = 20;
        Services.OSDService.lowBatteryAlerted = false;
        Services.OSDService.criticalBatteryAlerted = false;
        Services.OSDService.primed = false;
        Services.OSDService.clear();
        Services.OSDService.prime();
        if (!Services.OSDService.activeItem || Services.OSDService.activeItem.title !== "Low battery")
            return fail("low battery threshold did not produce a native alert");

        fakePower.percentage = 14;
        if (!Services.OSDService.activeItem || Services.OSDService.activeItem.title !== "Critical battery")
            return fail("critical battery threshold did not supersede the low alert");

        fakePower.charging = true;
        fakePower.charging = false;
        if (!Services.OSDService.activeItem || Services.OSDService.activeItem.title !== "Critical battery")
            return fail("battery alert latch was not reset after a charge cycle");

        Services.OSDService.clear();
        if (Services.OSDService.activeItem !== null || Services.OSDService.queue.length !== 0)
            return fail("clear did not release OSD state");
        done = true;
        console.log("OSD_SERVICE_TEST_PASSED");
        Qt.quit();
    }
}
