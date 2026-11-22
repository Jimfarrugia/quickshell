import QtQuick
import Quickshell
import "integrations" as Integrations
import "fixtures/qml" as Fixtures

// Adapter wiring only: refresh-cycle transitions, backoff, and coalescing are
// owned by tests/js/ai-quota-scheduler.test.mjs.
ShellRoot {
    id: root
    Fixtures.FakeQuotaRunner { id: fakeRunner }
    Integrations.AiQuotaAdapter {
        id: adapter
        runner: fakeRunner
        wakeWatcherEnabled: false
    }
    property var results: []
    property int resumes: 0

    function document(id) {
        const window = { status: "ok", usedPercent: 30, remainingPercent: 70,
            resetsAt: "2026-12-01T00:00:00Z", error: null };
        return { schemaVersion: 1, observedAt: "2026-11-22T00:00:00Z",
            providers: { [id]: { status: "ok", lastUpdated: "2026-11-22T00:00:00Z",
                fiveHour: window, weekly: window, error: null } } };
    }
    function fail(message) {
        console.error(`AI_QUOTA_ADAPTER_TEST_FAILED: ${message}`);
        Qt.quit();
    }
    function lastResult() { return results[results.length - 1]; }
    Connections {
        target: adapter
        function onRefreshed(result) { root.results = root.results.concat([result]); }
        function onResumed() { root.resumes++; }
    }

    function check() {
        if (adapter.operation !== "idle") return fail("adapter did not start idle");
        adapter.active = true;
        if (!fakeRunner.running || fakeRunner.command[2] !== "--provider" || fakeRunner.command[3] !== "claude")
            return fail(`activation did not start the first catalogued provider: ${JSON.stringify(fakeRunner.command)}`);
        if (!adapter.busy || adapter.operation !== "pending") return fail("refresh cycle was not pending");

        fakeRunner.finish({ success: true, parsed: document("claude"), cancelled: false });
        if (results.length !== 1 || !lastResult().ok || lastResult().providerId !== "claude"
                || lastResult().data.providers.claude.weekly.remainingPercent !== 70)
            return fail("validated helper document was not published with its provider");
        if (fakeRunner.command[3] !== "openai" || !adapter.busy)
            return fail("cycle did not advance to the next provider while pending");

        fakeRunner.failNextStart = true;
        fakeRunner.finish({ success: false, timedOut: true, cancelled: false });
        if (results[1].ok || results[1].error !== "TIMEOUT" || results[1].providerId !== "openai")
            return fail("timed-out helper was not published as a TIMEOUT failure");
        if (results.length !== 3 || results[2].error !== "FAILED_TO_START" || results[2].providerId !== "opencode")
            return fail("helper start failure was not published");
        if (adapter.busy || adapter.operation !== "succeeded")
            return fail(`completed cycle did not publish its outcome (${adapter.operation})`);

        if (!adapter.refresh() || !fakeRunner.running) return fail("manual refresh did not start the helper");
        fakeRunner.delayCancellation = true;
        adapter.consumeSleepLine("boolean true");
        if (fakeRunner.cancelCalls !== 1 || !adapter.sleeping || !adapter.busy)
            return fail("sleep did not cancel the running helper while staying pending");
        fakeRunner.completeCancellation();
        if (adapter.busy || results.length !== 3) return fail("cancellation was published or left pending");
        adapter.consumeSleepLine("boolean false");
        if (adapter.sleeping || resumes !== 1) return fail("wake did not report a resume");

        adapter.refresh();
        adapter.active = false;
        if (fakeRunner.cancelCalls !== 2) return fail("deactivation did not cancel the running helper");
        fakeRunner.completeCancellation();
        if (adapter.busy) return fail("deactivation left the adapter pending");

        console.log("AI_QUOTA_ADAPTER_TEST_PASSED");
        Qt.quit();
    }

    Timer { interval: 100; running: true; onTriggered: root.check() }
    Timer { interval: 5000; running: true; onTriggered: root.fail("test timed out") }
}
