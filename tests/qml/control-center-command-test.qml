import QtQuick
import Quickshell
import "integrations" as Integrations

ShellRoot {
    id: root

    property int completed: 0
    property bool powerDone: false
    property bool defaultsStarted: false

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
                console.log("CONTROL_CENTER_COMMAND_TEST_PASSED");
                Qt.quit();
            }
        }
    }

    function fail(message) {
        console.error(`CONTROL_CENTER_COMMAND_TEST_FAILED: ${message}`);
        Qt.exit(1);
    }

    function check() {
        if (!powerDone && !power.running) {
            if (!power.launch()) return fail("power menu command did not start");
        }
        if (!defaultsStarted && !defaults.running) {
            defaultsStarted = true;
            if (!defaults.start("capture")) return fail("defaults command did not start");
        }
    }

    Connections {
        target: power
        function onFinished(success, error) {
            if (!success || error.length !== 0)
                return root.fail("power menu adapter did not report success");
            root.powerDone = true;
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
