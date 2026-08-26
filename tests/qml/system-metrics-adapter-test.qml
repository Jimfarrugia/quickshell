import QtQuick
import Quickshell
import "integrations" as Integrations

ShellRoot {
    id: root

    property int cpuReads: 0
    property bool memoryRead: false
    property bool completed: false

    function fail(message) {
        console.error(`SYSTEM_METRICS_ADAPTER_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function maybeFinish() {
        if (!completed && cpuReads >= 2 && memoryRead) {
            completed = true;
            console.log("SYSTEM_METRICS_ADAPTER_TEST_PASSED");
            Qt.quit();
        }
    }

    Integrations.SystemMetricsProcAdapter {
        cpuActive: true
        memoryActive: true
        onCpuRead: (text, failed, error) => {
            if (failed || !text.startsWith("cpu "))
                return root.fail(`invalid CPU read: ${error}`);
            root.cpuReads++;
            root.maybeFinish();
        }
        onMemRead: (text, failed, error) => {
            if (failed || text.indexOf("MemTotal:") === -1)
                return root.fail(`invalid memory read: ${error}`);
            root.memoryRead = true;
            root.maybeFinish();
        }
    }

    Timer {
        interval: 4500
        running: true
        onTriggered: root.fail(`timed out after ${root.cpuReads} CPU reads; memoryRead=${root.memoryRead}`)
    }
}
