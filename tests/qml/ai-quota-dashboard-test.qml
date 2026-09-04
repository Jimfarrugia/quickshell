import QtQuick
import Quickshell
import "services" as Services
import "fixtures/qml" as Fixtures
import "modules/aiquota" as AiQuotaModules

ShellRoot {
    id: root
    Fixtures.FakeAiQuotaAdapter { id: fake }
    Binding {
        target: Services.AiQuotaService
        property: "adapter"
        value: fake
        restoreMode: Binding.RestoreBindingOrValue
    }
    AiQuotaModules.AiQuotaDashboard {
        id: dashboard
        visible: true
        width: 572
    }
    property var quotaDocument: ({
        schemaVersion: 1, observedAt: new Date().toISOString(), providers: {
            openai: { status: "ok", lastUpdated: new Date().toISOString(), error: null,
                fiveHour: { status: "ok", usedPercent: 25, remainingPercent: 75, resetsAt: "2026-09-04T05:00:00Z", error: null },
                weekly: { status: "ok", usedPercent: 40, remainingPercent: 60, resetsAt: "2026-09-11T00:00:00Z", error: null } },
            opencode: { status: "ok", lastUpdated: new Date().toISOString(), error: null,
                fiveHour: { status: "ok", usedPercent: 10, remainingPercent: 90, resetsAt: "2026-09-04T05:00:00Z", error: null },
                weekly: { status: "ok", usedPercent: 20, remainingPercent: 80, resetsAt: "2026-09-11T00:00:00Z", error: null },
                monthly: { status: "ok", usedPercent: 30, remainingPercent: 70, resetsAt: "2026-10-01T00:00:00Z", error: null } }
        }
    })
    property bool done: false
    function textFor(item, name) {
        if (!item) return "";
        if (item.objectName === name) return item.text || "";
        for (const child of item.children || []) {
            const text = textFor(child, name);
            if (text.length > 0) return text;
        }
        return "";
    }
    function objectFor(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const found = objectFor(child, name);
            if (found) return found;
        }
        return null;
    }
    function fail(message) { console.error(`AI_QUOTA_DASHBOARD_TEST_FAILED: ${message}`); root.done = true; Qt.quit(); }
    Timer {
        interval: 100
        running: !root.done
        repeat: false
        onTriggered: {
            Services.AiQuotaService.selectedProvider = "openai";
            fake.publish(root.quotaDocument);
            fake.busy = true;
            if (root.textFor(dashboard, "last-checked") !== "Refreshing...") return root.fail("pending status did not replace last checked");
            fake.busy = false;
            if (root.textFor(dashboard, "last-checked").indexOf("Updated") < 0) return root.fail("updated status was not restored");
            else if (root.textFor(dashboard, "openai-Weekly Limit-details").indexOf("Resets in ") < 0
                || root.textFor(dashboard, "openai-Weekly Limit-details").indexOf(" on ") < 0
                || root.textFor(dashboard, "openai-Weekly Limit-details").indexOf("Used ") >= 0
                || root.objectFor(dashboard, "openai-Weekly Limit-details").textFormat !== Text.RichText
                || root.textFor(dashboard, "openai-Weekly Limit-details").indexOf("<b>") < 0) return root.fail("reset details did not use the requested format");
            if (dashboard.implicitHeight <= 0) root.fail("dashboard has no content height");
            else if (Services.AiQuotaService.tooltipText.indexOf("OpenCode Go") < 0) root.fail("tooltip omitted the second provider");
            else if (root.objectFor(dashboard, "openai-freshness").visible) return root.fail(`current provider label was displayed (${Services.AiQuotaService.provider("openai").freshness})`);
            else if (root.textFor(dashboard, "openai-Weekly Limit-remaining").indexOf("60%") < 0
                || root.textFor(dashboard, "opencode-5-hour Limit-remaining").indexOf("90%") < 0
                || root.textFor(dashboard, "opencode-Monthly Limit-remaining").indexOf("70%") < 0) root.fail("dashboard omitted independent quota values");
            else if (root.objectFor(dashboard, "openai-Weekly Limit-details").width
                > root.objectFor(dashboard, "openai-Weekly Limit-details").parent.width
                || root.objectFor(dashboard, "openai-Weekly Limit-progress").width
                > root.objectFor(dashboard, "openai-Weekly Limit-progress").parent.width)
                root.fail("OpenAI quota content exceeded its row width");
            else if (root.objectFor(dashboard, "openai-Weekly Limit-remaining").width
                > root.objectFor(dashboard, "openai-Weekly Limit-remaining").parent.width)
                root.fail("OpenAI remaining label exceeded its row width");
            else if (root.objectFor(dashboard, "last-checked").width > dashboard.width)
                root.fail(`last-checked label exceeded the dashboard width (${root.objectFor(dashboard, "last-checked").width} > ${dashboard.width})`);
            else if (Math.abs(root.objectFor(dashboard, "opencode-section").mapToItem(dashboard, 0, 0).y
                - root.objectFor(dashboard, "openai-section").mapToItem(dashboard, 0, 0).y
                - root.objectFor(dashboard, "openai-section").height - 20) > 0.5)
                root.fail("provider sections were not separated by 20px");
            else if (Math.abs(root.objectFor(dashboard, "openai-heading").mapToItem(dashboard, 0, 0).y
                - root.objectFor(dashboard, "openai-section").mapToItem(dashboard, 0, 0).y - 12) > 0.5
                || Math.abs(root.objectFor(dashboard, "openai-5-hour Limit-heading").mapToItem(dashboard, 0, 0).y
                    - root.objectFor(dashboard, "openai-heading").mapToItem(dashboard, 0, 0).y
                    - root.objectFor(dashboard, "openai-heading").height - 12) > 0.5)
                root.fail("provider heading spacing was not 12px");
            else if (Math.abs(root.objectFor(dashboard, "openai-5-hour Limit-details").mapToItem(dashboard, 0, 0).y
                - root.objectFor(dashboard, "openai-5-hour Limit-progress").mapToItem(dashboard, 0, 0).y
                - root.objectFor(dashboard, "openai-5-hour Limit-progress").height - 6) > 0.5)
                root.fail("progress bar bottom spacing was not 6px");
            else if (Math.abs(root.objectFor(dashboard, "openai-5-hour Limit-progress").mapToItem(dashboard, 0, 0).y
                - root.objectFor(dashboard, "openai-5-hour Limit-heading").mapToItem(dashboard, 0, 0).y
                - root.objectFor(dashboard, "openai-5-hour Limit-heading").height - 6) > 0.5)
                root.fail("progress bar title bottom spacing was not 6px");
            else if (Math.abs(root.objectFor(dashboard, "openai-Weekly Limit-heading").mapToItem(dashboard, 0, 0).y
                - root.objectFor(dashboard, "openai-5-hour Limit-details").mapToItem(dashboard, 0, 0).y
                - root.objectFor(dashboard, "openai-5-hour Limit-details").height - 12) > 0.5)
                root.fail("second progress bar title top spacing was not 12px");
            else if (!root.objectFor(dashboard, "opencode-Weekly Limit-progress").contentItem.clip)
                root.fail("OpenCode indeterminate progress was not clipped");
            else if (String(root.objectFor(dashboard, "openai-Weekly Limit-track").color)
                !== String(Services.ThemeService.theme.tokens.surface_low))
                root.fail("progress bar track did not use surface_low");
            else if (root.objectFor(dashboard, "openai-Weekly Limit-track").radius !== 0)
                root.fail("progress bar track corners were not uniform");
            else if (String(root.objectFor(dashboard, "openai-section").color)
                !== String(Services.ThemeService.theme.tokens.surface))
                root.fail("provider section did not use surface");
            else if (Services.AiQuotaService.consumerCount !== 1) root.fail("visible dashboard did not register as a consumer");
            else {
                const old = Object.assign({}, Services.AiQuotaService.provider("openai"), { lastUpdated: new Date(Date.now() - 900001) });
                Services.AiQuotaService.providers = Object.assign({}, Services.AiQuotaService.providers, { openai: old });
                Services.AiQuotaService.markStale();
                if (root.textFor(dashboard, "openai-Weekly Limit-remaining").indexOf("stale") < 0) return root.fail("dashboard omitted stale state");
                if (root.textFor(dashboard, "openai-freshness") !== "stale data") return root.fail("dashboard omitted stale provider label");
                if (String(root.objectFor(dashboard, "openai-freshness").color) !== String(Services.ThemeService.theme.tokens.warning)) return root.fail("stale provider label was not warning-colored");
                Services.AiQuotaService.providers = Object.assign({}, Services.AiQuotaService.providers, { opencode: Services.AiQuotaService.blankProvider("opencode") });
                if (root.textFor(dashboard, "opencode-Weekly Limit-remaining") !== "Unavailable") return root.fail("dashboard omitted unavailable state");
                if (root.textFor(dashboard, "opencode-freshness") !== "unknown data") return root.fail("dashboard omitted unknown provider label");
                dashboard.visible = false;
                if (Services.AiQuotaService.consumerCount !== 0) root.fail("hidden dashboard did not release its consumer");
                else { console.log("AI_QUOTA_DASHBOARD_TEST_PASSED"); root.done = true; Qt.quit(); }
            }
        }
    }
    Timer { interval: 3000; running: !root.done; onTriggered: root.fail("test timed out") }
}
