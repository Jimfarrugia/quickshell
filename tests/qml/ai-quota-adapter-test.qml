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
        wakeWatcherEnabled: false
    }
    property int stage: 0
    property bool done: false
    property bool sleepRequested: false

    function window(used, reset) {
        return { status: "ok", usedPercent: used, remainingPercent: 100 - used,
            resetsAt: reset, error: null };
    }
    function provider(status, five, weekly, failure) {
        return { status: status, lastUpdated: "2026-09-04T00:00:00Z",
            fiveHour: five, weekly: weekly, error: failure || null };
    }
    function document(id, failure) {
        const good = provider("ok", window(20, "2026-09-04T05:00:00Z"),
            window(30, "2026-09-11T00:00:00Z"), null);
        if (id === "opencode" && failure) {
            const errorWindow = { status: "error", usedPercent: null,
                remainingPercent: null, resetsAt: null, error: failure };
            return { schemaVersion: 1, observedAt: "2026-09-04T00:00:00Z",
                providers: { opencode: provider("error", errorWindow, errorWindow, failure) } };
        }
        return { schemaVersion: 1, observedAt: "2026-09-04T00:00:00Z",
            providers: { [id]: good } };
    }
    function fail(message) {
        console.error(`AI_QUOTA_ADAPTER_TEST_FAILED: ${message}`);
        done = true;
        Qt.quit();
    }
    Connections {
        target: adapter
        function onResumed() { adapter.requestCycle("resume"); }
        function onRefreshed(result) {
            if (!result.providerId) return root.fail("adapter omitted provider identity");
            if (root.stage === 0) {
                if (result.providerId !== "openai") return root.fail("first request was not OpenAI");
                if (adapter.busy !== true) return root.fail("refresh cycle was not kept busy between providers");
                root.stage = 1;
            } else if (root.stage === 1) {
                if (result.providerId !== "opencode") return root.fail("shared poller did not advance to OpenCode");
                if (adapter.nextAllowedAt.opencode - Date.now() < 3500000)
                    return root.fail("Retry-After was not converted from seconds to milliseconds");
                root.stage = 2;
            }
        }
    }
    Timer {
        interval: 100
        running: !root.done
        repeat: true
        onTriggered: {
            if (root.stage === 0) {
                if (!fakeRunner.running || fakeRunner.command[3] !== "openai")
                    return root.fail(`first command was ${JSON.stringify(fakeRunner.command)}`);
                fakeRunner.finish({ success: true, parsed: root.document("openai"), cancelled: false });
            } else if (root.stage === 1 && fakeRunner.running && fakeRunner.command[3] === "opencode") {
                fakeRunner.finish({ success: true, parsed: root.document("opencode",
                    { code: "RATE_LIMITED", retryable: true, retryAfterSeconds: 3600 }), cancelled: false });
            } else if (root.stage === 2 && !adapter.busy) {
                if (adapter.failureStreak.openai !== 0 || adapter.failureStreak.opencode !== 1)
                    return root.fail("failure state was not scoped per provider");
                adapter.backoff("openai", "NETWORK_ERROR", null);
                const startsBeforeManual = fakeRunner.startCalls;
                if (!adapter.refresh()) return root.fail("manual refresh was rejected during local backoff");
                if (!adapter.busy || !fakeRunner.running || fakeRunner.command[3] !== "openai")
                    return root.fail("manual refresh did not bypass local backoff");
                if (fakeRunner.startCalls !== startsBeforeManual + 1)
                    return root.fail("manual refresh did not start exactly one provider request");
                root.stage = 3;
            } else if (root.stage === 3 && fakeRunner.running && !root.sleepRequested) {
                root.sleepRequested = true;
                fakeRunner.delayCancellation = true;
                adapter.nextAllowedAt.openai = 0;
                adapter.consumeSleepLine("boolean true");
                if (!adapter.sleeping || !adapter.busy || fakeRunner.cancelCalls !== 1)
                    return root.fail("sleep did not cancel the active request while remaining pending");
                if (!adapter.refresh() || adapter.queuedReason !== "manual")
                    return root.fail("manual refresh was not retained while sleeping");
                adapter.consumeSleepLine("boolean false");
                adapter.consumeSleepLine("boolean false");
                if (adapter.queuedReason !== "manual")
                    return root.fail("resume did not preserve the queued manual refresh");
                fakeRunner.completeCancellation();
                root.stage = 4;
            } else if (root.stage === 4 && fakeRunner.running) {
                if (fakeRunner.command[3] !== "openai")
                    return root.fail("resume did not start a fresh OpenAI request");
                fakeRunner.finish({ success: true, parsed: root.document("openai"), cancelled: false });
            } else if (root.stage === 4 && !adapter.busy) {
                if (fakeRunner.startCalls !== 4)
                    return root.fail(`resume/manual cycles were duplicated or dropped (${fakeRunner.startCalls})`);
                adapter.active = false;
                console.log("AI_QUOTA_ADAPTER_TEST_PASSED");
                root.done = true;
                Qt.quit();
            }
        }
    }
    Timer { interval: 5000; running: !root.done; onTriggered: root.fail(`test timed out at stage ${root.stage}: ${JSON.stringify(fakeRunner.command)}`) }
}
