pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../integrations" as Integrations
import "../utils/AiQuota.mjs" as AiQuota

Singleton {
    id: root

    readonly property var providerIds: ["openai", "opencode"]
    property int consumerCount: 0
    property string selectedProvider: "openai"
    property bool stateReady: false
    property var providers: ({
        openai: AiQuota.blankProvider("openai"),
        opencode: AiQuota.blankProvider("opencode")
    })
    readonly property string availability: aggregate("availability", "unavailable")
    readonly property string freshness: aggregate("freshness", "unknown")
    readonly property var lastUpdated: latestUpdate()
    readonly property var lastError: firstError()
    readonly property string operation: adapter.busy ? "pending" : "idle"
    readonly property bool polling: consumerCount > 0
    readonly property int refreshIntervalMs: 300000
    readonly property string tooltipText: tooltip()
    property var adapter: Integrations.AiQuotaAdapter { id: realAdapter }

    function provider(id) { return providers[id] || AiQuota.blankProvider(id); }
    function window(id, name) { return provider(id)[name] || AiQuota.blankWindow(); }
    function aggregate(field, fallback) {
        const values = providerIds.map(id => provider(id)[field]);
        if (values.length === 0) return fallback;
        if (values.every(value => value === "available")) return "available";
        if (values.every(value => value === "unavailable")) return "unavailable";
        if (values.some(value => value === "unknown")) return "unknown";
        return "degraded";
    }
    function latestUpdate() {
        const dates = providerIds.map(id => provider(id).lastUpdated)
            .filter(value => value instanceof Date);
        return dates.length ? new Date(Math.max(...dates.map(value => value.getTime()))) : null;
    }
    function firstError() {
        return providerIds.map(id => provider(id).lastError).find(value => value !== null) || null;
    }
    function displayWindow(id, name) {
        const item = window(id, name);
        if (item.status !== "ok") return "-- (unavailable)";
        return `${AiQuota.formatPercent(item.remainingPercent)}% remaining${item.freshness === "stale" ? " (stale)" : ""}`;
    }
    function tooltip() {
        return providerIds.map(id => `${AiQuota.providerLabel(id)}: ${displayWindow(id, "weekly")}`).join("\n");
    }
    function publish(result) {
        providers = AiQuota.mergeQuotaResult(providers, result, Date.now());
    }
    function registerConsumer() { consumerCount++; updateAdapter(); }
    function unregisterConsumer() { consumerCount = Math.max(0, consumerCount - 1); updateAdapter(); }
    function updateAdapter() { adapter.active = consumerCount > 0; }
    function requestCycle(reason) { return adapter.requestCycle(reason); }
    function refresh() { return requestCycle("manual"); }
    function refreshIfDue(reason) {
        markStale();
        if (!polling) return false;
        const now = Date.now();
        const due = providerIds.some(id => {
            const attempt = provider(id).lastAttempt;
            return !(attempt instanceof Date) || !Number.isFinite(attempt.getTime())
                || attempt.getTime() > now || now - attempt.getTime() >= refreshIntervalMs;
        });
        return due ? requestCycle(reason || "poll") : false;
    }
    function cycleProvider() {
        const index = providerIds.indexOf(selectedProvider);
        selectedProvider = providerIds[(index + 1) % providerIds.length];
        if (stateReady) stateFile.setText(JSON.stringify({ schemaVersion: 1, selectedProvider: selectedProvider }, null, 2) + "\n");
    }
    function loadState() {
        if (!stateFile.loaded) return;
        stateReady = true;
        try {
            const parsed = AiQuota.validateAiQuotaState(JSON.parse(stateFile.text()));
            if (parsed.ok) selectedProvider = parsed.value.selectedProvider;
            else DiagnosticsService.report("AI_QUOTA_STATE_REJECTED", "ai-quota", "AI quota selection state ignored", "Invalid ai-quota.json", false, null);
        } catch (error) {
            DiagnosticsService.report("AI_QUOTA_STATE_REJECTED", "ai-quota", "AI quota selection state ignored", "Malformed ai-quota.json", false, null);
        }
    }

    Connections {
        target: root.adapter
        function onRefreshed(result) { root.publish(result); }
        function onResumed() { root.refreshIfDue("resume"); }
    }
    Timer {
        interval: root.refreshIntervalMs
        repeat: true
        running: root.polling
        onTriggered: root.refreshIfDue("poll")
    }
    Timer {
        interval: 60000
        repeat: true
        running: root.polling
        onTriggered: root.markStale()
    }
    function markStale() {
        providers = AiQuota.markProvidersStale(providers, Date.now());
    }
    FileView {
        id: stateFile
        path: PathsService.aiQuotaState
        blockLoading: true
        atomicWrites: true
        printErrors: false
        onLoaded: root.loadState()
        onLoadFailed: root.stateReady = true
    }
    onAdapterChanged: updateAdapter()
    Component.onCompleted: { loadState(); updateAdapter(); }
}
