import QtQuick
import Quickshell
import "integrations" as Integrations
import "services" as Services

ShellRoot {
    id: root
    property int stage: 0
    property string confirmedState: "unchanged"

    function fail(message) {
        console.error(`COMMAND_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    Integrations.CommandRunner {
        id: runner
        timeoutMs: 150
        termGraceMs: 50
        expectJson: true
        onFinished: result => {
            if (root.stage === 0) {
                if (!result.timedOut || result.success || root.confirmedState !== "unchanged")
                    return root.fail("timeout result was allowed to mutate confirmed state");
                root.stage = 1;
                command = ["/usr/bin/cat", Services.PathsService.shellPath("tests/fixtures/command/malformed.txt")];
                timeoutMs = 1000;
                start();
            } else if (root.stage === 1) {
                if (result.parseError === null || result.success || root.confirmedState !== "unchanged")
                    return root.fail("malformed output was allowed to mutate confirmed state");
                root.stage = 2;
                command = ["/qe/fixture/does-not-exist"];
                start();
            } else if (root.stage === 2) {
                if (result.errorCode !== "FAILED_TO_START" || result.success || root.confirmedState !== "unchanged")
                    return root.fail("missing executable did not produce a bounded failure");
                root.stage = 3;
                expectJson = false;
                maxStdoutBytes = 64;
                command = ["/usr/bin/seq", "1", "1000"];
                start();
            } else if (root.stage === 3) {
                if (!result.success || !result.stdoutTruncated || result.stdout.length > 64)
                    return root.fail("stdout retention was not bounded");
                root.stage = 4;
                command = ["/usr/bin/sleep", "2"];
                start();
                cancelTimer.start();
            } else if (root.stage === 4) {
                if (!result.cancelled || result.success || root.confirmedState !== "unchanged")
                    return root.fail("cancelled operation was allowed to mutate confirmed state");
                root.stage = 5;
                expectJson = true;
                maxStdoutBytes = 32768;
                command = ["/usr/bin/cat", Services.PathsService.shellPath("tests/fixtures/command/valid.json")];
                start();
            } else {
                if (!result.success || result.parsed.status !== "ok")
                    return root.fail("valid structured result was rejected");
                root.confirmedState = result.parsed.status;
                if (root.confirmedState !== "ok") return root.fail("valid result did not update confirmed state");
                console.log("COMMAND_TEST_PASSED");
                Qt.quit();
            }
        }
        Component.onCompleted: {
            command = ["/usr/bin/sleep", "2"];
            start();
        }
    }

    Timer {
        id: cancelTimer
        interval: 50
        repeat: false
        onTriggered: runner.cancel()
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: {
            console.error("COMMAND_TEST_FAILED: command runner test timed out");
            Qt.quit();
        }
    }
}
