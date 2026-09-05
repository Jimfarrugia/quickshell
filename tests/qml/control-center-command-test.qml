import QtQuick
import Quickshell
import "integrations" as Integrations

ShellRoot {
    id: root

    property int completed: 0
    property bool powerDone: false
    property bool defaultsStarted: false
    property bool defaultsDone: false
    property bool monitorsStarted: false
    property bool monitorsDone: false
    property bool monitorValidationChecked: false

    Integrations.PowerMenuAdapter {
        id: power
        executable: "/usr/bin/true"
    }

    Integrations.DefaultsCommandAdapter {
        id: defaults
        executable: "/usr/bin/true"
        onFinished: (action, result) => {
            if (action === "capture") {
                if (!result.success) return root.fail("successful defaults command was rejected");
                root.completed++;
                defaults.executable = "/usr/bin/false";
                Qt.callLater(() => {
                    if (!defaults.start("restore"))
                        root.fail("failed defaults command did not start");
                });
            } else {
                if (result.success) return root.fail("failed defaults command reported success");
                root.defaultsDone = true;
                root.maybeFinish();
            }
        }
    }

    Integrations.MonitorLayoutAdapter {
        id: monitors
        executable: Quickshell.shellPath("../fixtures/monitor-layout/adapter-result")
        onFinished: (action, result) => {
            if (action !== "apply" || !result.success || result.parsed.direction !== "right"
                    || result.parsed.primaryScale !== 1.25
                    || result.parsed.secondaryScale !== 1.5)
                return root.fail("monitor layout adapter rejected valid structured output");
            root.completed++;
            root.monitorsDone = true;
            root.maybeFinish();
        }
    }

    function fail(message) {
        console.error(`CONTROL_CENTER_COMMAND_TEST_FAILED: ${message}`);
        Qt.exit(1);
    }

    function maybeFinish() {
        if (!powerDone || !defaultsDone || !monitorsDone) return;
        console.log("CONTROL_CENTER_COMMAND_TEST_PASSED");
        Qt.quit();
    }

    function check() {
        if (!powerDone && !power.running) {
            if (!power.launch()) return fail("power menu command did not start");
        }
        if (!defaultsStarted && !defaults.running) {
            defaultsStarted = true;
            if (!defaults.start("capture")) return fail("defaults command did not start");
        }
        if (!monitorsStarted && !monitors.running) {
            if (!monitorValidationChecked) {
                monitorValidationChecked = true;
                const invalid = monitors.validateResult({
                    success: true,
                    parsed: { version: 1 }
                });
                if (invalid.success)
                    return fail("monitor layout adapter accepted an invalid document");
                if (monitors.start("apply", "extended", "right", 1.4, 1.5))
                    return fail("monitor layout adapter accepted an invalid scale");
            }
            monitorsStarted = true;
            if (!monitors.start("apply", "extended", "right", 1.25, 1.5))
                return fail("monitor layout command did not start");
        }
    }

    Connections {
        target: power
        function onFinished(success, error) {
            if (!success || error.length !== 0)
                return root.fail("power menu adapter did not report success");
            root.powerDone = true;
            root.maybeFinish();
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: root.check()
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail("command adapter test timed out")
    }
}
