import QtQuick
import Quickshell
import "integrations" as Integrations

ShellRoot {
    id: root

    readonly property string sensorPath: Quickshell.shellPath(
        "tests/fixtures/system-metrics/sys/class/hwmon/hwmon0/temp1_input")

    function fail(message) {
        console.error(`SYSTEM_METRICS_HELPER_ADAPTER_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    Integrations.SystemMetricsHelperAdapter {
        id: adapter
        onThermalRead: result => {
            if (!result.ok) return root.fail(result.error);
            const sensor = result.data.sensors[0];
            if (adapter.thermalRunner.running
                    || sensor.path !== root.sensorPath
                    || sensor.name !== "k10temp"
                    || sensor.label !== "Tctl"
                    || sensor.temp !== 42850)
                return root.fail("selected sensor FileView result was not normalized");
            console.log("SYSTEM_METRICS_HELPER_ADAPTER_TEST_PASSED");
            Qt.quit();
        }
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: root.fail("test timed out")
    }

    Component.onCompleted: {
        adapter.thermalSensors = [{
            name: "k10temp",
            label: "Tctl",
            path: sensorPath,
            temp: 0
        }];
        adapter.thermalSensorPath = sensorPath;
        adapter.thermalActive = true;
    }
}
