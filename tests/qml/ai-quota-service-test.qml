import QtQuick
import Quickshell
import "services" as Services
import "fixtures/qml" as Fixtures

ShellRoot {
    id: root
    Fixtures.FakeAiQuotaAdapter { id: fake }
    Binding {
        target: Services.AiQuotaService
        property: "adapter"
        value: fake
        restoreMode: Binding.RestoreBindingOrValue
    }
    property var quotaDocument: ({
        schemaVersion: 1,
        observedAt: new Date().toISOString(),
        providers: {
            openai: { status: "ok", lastUpdated: new Date().toISOString(), error: null,
                fiveHour: { status: "ok", usedPercent: 25, remainingPercent: 75, resetsAt: "2026-09-04T05:00:00Z", error: null },
                weekly: { status: "ok", usedPercent: 40, remainingPercent: 60, resetsAt: "2026-09-11T00:00:00Z", error: null } },
            opencode: { status: "ok", lastUpdated: new Date().toISOString(), error: null,
                fiveHour: { status: "ok", usedPercent: 10, remainingPercent: 90, resetsAt: "2026-09-04T05:00:00Z", error: null },
                weekly: { status: "ok", usedPercent: 20, remainingPercent: 80, resetsAt: "2026-09-11T00:00:00Z", error: null } }
        }
    })
    property bool done: false

    function fail(message) {
        console.error(`AI_QUOTA_SERVICE_TEST_FAILED: ${message}`);
        Qt.quit();
    }
    Component.onCompleted: {
        Services.AiQuotaService.selectedProvider = "openai";
        fake.busy = true;
        if (Services.AiQuotaService.operation !== "pending")
            return fail("service did not expose the adapter refresh cycle as pending");
        fake.busy = false;
        Services.AiQuotaService.registerConsumer();
        const refreshBeforeResume = fake.refreshCalls;
        fake.resumed();
        if (fake.refreshCalls <= refreshBeforeResume)
            return fail("resume event did not request an immediate refresh");
        fake.publish(root.quotaDocument);
        if (Services.AiQuotaService.provider("openai").weekly.remainingPercent !== 60
                || Services.AiQuotaService.provider("opencode").fiveHour.remainingPercent !== 90)
            return fail("provider windows were not normalized");
        Services.AiQuotaService.cycleProvider();
        if (Services.AiQuotaService.selectedProvider !== "opencode")
            return fail("provider selection did not cycle globally");
        fake.refreshed({ ok: false, error: "RATE_LIMITED", providerId: "openai" });
        if (Services.AiQuotaService.provider("openai").weekly.freshness !== "current"
                || Services.AiQuotaService.provider("openai").weekly.remainingPercent !== 60
                || Services.AiQuotaService.provider("opencode").weekly.freshness !== "current")
            return fail("provider-local current/LKG handling was incorrect");
        const oldProvider = Object.assign({}, Services.AiQuotaService.provider("openai"), { lastUpdated: new Date(Date.now() - 900001) });
        Services.AiQuotaService.providers = Object.assign({}, Services.AiQuotaService.providers, { openai: oldProvider });
        Services.AiQuotaService.markStale();
        if (Services.AiQuotaService.provider("openai").weekly.freshness !== "stale")
            return fail("stale threshold did not update the retained window");
        Services.AiQuotaService.unregisterConsumer();
        if (Services.AiQuotaService.consumerCount !== 0 || Services.AiQuotaService.polling)
            return fail("consumer lifecycle did not stop polling");
        console.log("AI_QUOTA_SERVICE_TEST_PASSED");
        root.done = true;
        Qt.quit();
    }
    Timer { interval: 2500; running: !root.done; onTriggered: root.fail("test timed out") }
}
