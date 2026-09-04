import QtQuick
import Quickshell
import "integrations" as Integrations
import "fixtures/qml" as Fixtures

ShellRoot {
    id: root
    Fixtures.FakeQuotaRunner { id: fakeRunner }
    Integrations.AiQuotaAdapter {
        id: adapter
        active: true
        runner: fakeRunner
    }
    property int stage: 0
    property bool done: false
    function window(used, reset) { return { status: "ok", usedPercent: used, remainingPercent: 100 - used, resetsAt: reset, error: null }; }
    function provider(status, five, weekly, failure) { return { status: status, lastUpdated: "2026-09-04T00:00:00Z", fiveHour: five, weekly: weekly, error: failure || null }; }
    function document(id, failure) {
        const good = provider("ok", window(20, "2026-09-04T05:00:00Z"), window(30, "2026-09-11T00:00:00Z"), null);
        if (id === "opencode" && failure) {
            const errorWindow = { status: "error", usedPercent: null, remainingPercent: null, resetsAt: null, error: failure };
            return { schemaVersion: 1, observedAt: "2026-09-04T00:00:00Z", providers: { opencode: provider("error", errorWindow, errorWindow, failure) } };
        }
        return { schemaVersion: 1, observedAt: "2026-09-04T00:00:00Z", providers: { [id]: good } };
    }
    function fail(message) { console.error(`AI_QUOTA_ADAPTER_TEST_FAILED: ${message}`); done = true; Qt.quit(); }
    Connections {
        target: adapter
        function onRefreshed(result) {
            if (!result.providerId) return root.fail("adapter omitted provider identity");
            if (root.stage === 0) {
                if (result.providerId !== "openai") return root.fail("first request was not OpenAI");
                if (adapter.busy !== true) return root.fail("refresh cycle was not kept busy between providers");
                root.stage = 1;
            } else if (root.stage === 1) {
                if (result.providerId !== "opencode") return root.fail("shared poller did not advance to OpenCode");
                root.stage = 2;
            }
        }
    }
    Timer {
        interval: 100
        running: !root.done
        repeat: true
        onTriggered: {
            if (root.stage === 0) { if (fakeRunner.command[3] !== "openai") return root.fail(`first command was ${JSON.stringify(fakeRunner.command)}`); fakeRunner.running = false; adapter.pendingProvider = "openai"; adapter.publish({ success: true, parsed: root.document("openai"), cancelled: false }); }
            else if (root.stage === 1 && fakeRunner.command[3] === "opencode") { fakeRunner.running = false; adapter.pendingProvider = "opencode"; adapter.publish({ success: true, parsed: root.document("opencode", { code: "RATE_LIMITED", retryable: true, retryAfterSeconds: 3600 }), cancelled: false }); }
            else if (root.stage === 2) {
                if (fakeRunner.command[3] === "openai") return root.fail("refresh cycle restarted before the five-minute interval");
                if (adapter.busy) return root.fail("refresh cycle remained busy after all providers completed");
                if (adapter.nextAllowedAt.opencode <= Date.now() || adapter.failureStreak.opencode !== 1) return root.fail("Retry-After was not scoped to OpenCode");
                if (adapter.failureStreak.openai !== 0) return root.fail("unaffected OpenAI provider was incorrectly backed off");
                adapter.backoff("openai", "NETWORK_ERROR", null);
                adapter.backoff("openai", "NETWORK_ERROR", null);
                adapter.backoff("openai", "NETWORK_ERROR", null);
                if (adapter.failureStreak.openai !== 3) return root.fail("backoff streak was not bounded");
                console.log("AI_QUOTA_ADAPTER_TEST_PASSED");
                root.done = true;
                Qt.quit();
            }
        }
    }
    Timer { interval: 5000; running: !root.done; onTriggered: root.fail(`test timed out at stage ${root.stage}: ${JSON.stringify(fakeRunner.command)}`) }
}
