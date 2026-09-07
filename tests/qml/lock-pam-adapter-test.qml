import QtQuick
import Quickshell
import "lock" as Lock

ShellRoot {
    id: root

    property int completions: 0
    property string result: ""
    property int completedAttemptId: 0

    property Component fakeAttemptFactory: Component {
        QtObject {
            required property int attemptId
            property bool active: false
            property bool responseRequired: false
            property bool responseVisible: false
            property string message: ""
            signal completed(string result, int attemptId)
            signal failed(int attemptId)
            function start() { active = true; responseRequired = true; return true; }
            function respond(response) { responseRequired = false; }
            function abort() { active = false; responseRequired = false; }
        }
    }

    Lock.LockPamAdapter {
        id: adapter
        attemptFactory: root.fakeAttemptFactory
        onCompleted: (completedResult, attemptId) => {
            root.completions++;
            root.result = completedResult;
            root.completedAttemptId = attemptId;
        }
    }

    function fail(message) {
        console.error(`LOCK_PAM_ADAPTER_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function runChecks() {
        if (!adapter.start() || adapter.attemptId !== 1)
            return fail("first PAM attempt did not start");
        const staleAttempt = adapter.attempt;
        adapter.abort();
        if (!adapter.start() || adapter.attemptId !== 2)
            return fail("replacement PAM attempt did not start");
        staleAttempt.completed("success", staleAttempt.attemptId);
        if (completions !== 0 || adapter.attempt === null)
            return fail("aborted PAM attempt reached the adapter");
        adapter.attempt.completed("success", adapter.attempt.attemptId);
        if (completions !== 1 || result !== "success" || completedAttemptId !== 2
                || adapter.attempt !== null)
            return fail("current PAM completion was not normalized with its immutable ID");
        if (!adapter.start() || adapter.attemptId !== 3)
            return fail("PAM replacement attempt did not start after success");
        adapter.attempt.failed(adapter.attempt.attemptId);
        if (completions !== 2 || result !== "failed" || completedAttemptId !== 3
                || adapter.attempt !== null)
            return fail("PAM error was not normalized as a failed current attempt");
        console.log("LOCK_PAM_ADAPTER_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: root.fail("test timed out")
    }

    Component.onCompleted: Qt.callLater(runChecks)
}
