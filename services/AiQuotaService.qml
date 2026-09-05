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
        openai: blankProvider("openai"),
        opencode: blankProvider("opencode")
    })
    readonly property string availability: aggregate("availability", "unavailable")
    readonly property string freshness: aggregate("freshness", "unknown")
    readonly property var lastUpdated: latestUpdate()
    readonly property var lastError: firstError()
    readonly property string operation: adapter.busy ? "pending" : "idle"
    readonly property bool polling: consumerCount > 0
    readonly property string tooltipText: tooltip()
    property var adapter: Integrations.AiQuotaAdapter { id: realAdapter }

    function blankWindow() {
        return { status: "error", usedPercent: null, remainingPercent: null,
            resetsAt: null, error: null, freshness: "unknown", lastUpdated: null };
    }
    function blankProvider(id) {
        return { id: id, label: AiQuota.providerLabel(id), availability: "unknown",
            freshness: "unknown", lastUpdated: null, lastAttempt: null, lastError: null,
            fiveHour: blankWindow(), weekly: blankWindow(), monthly: blankWindow() };
    }
    function provider(id) { return providers[id] || blankProvider(id); }
    function window(id, name) { return provider(id)[name] || blankWindow(); }
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
    function errorObject(code) {
        const retryable = ["TIMEOUT", "NETWORK_ERROR", "RATE_LIMITED", "AUTH_EXPIRED"].indexOf(code) !== -1;
        return { code: code, boundary: "ai-quota", summary: safeErrorSummary(code), detail: "", timestamp: new Date(), retryable: retryable, operationId: null };
    }
    function safeErrorSummary(code) {
        if (code === "AUTH_EXPIRED") return "Open OpenCode to refresh the OpenAI login";
        if (code === "AUTH_MISSING") return "OpenCode credentials are not configured";
        if (code === "NOT_ENTITLED") return "OpenCode Go is not enabled for this account";
        if (code === "RATE_LIMITED") return "Quota service rate limited";
        if (code === "UNAUTHORIZED") return "Provider authentication was rejected";
        return "Provider quota is temporarily unavailable";
    }
    function publishFailure(code, providerId) {
        const now = new Date();
        const next = Object.assign({}, providers);
        (providerId ? [providerId] : providerIds).forEach(id => {
            const current = provider(id);
            const age = current.lastUpdated instanceof Date ? now - current.lastUpdated : Infinity;
            const hasValue = current.fiveHour.status === "ok" || current.weekly.status === "ok";
            const stale = hasValue && age >= 900000;
            const failure = errorObject(code);
            const windows = {};
            ["fiveHour", "weekly", "monthly"].forEach(name => windows[name] = Object.assign({}, current[name], { error: failure, freshness: hasValue && current[name].status === "ok" ? (stale ? "stale" : "current") : current[name].freshness }));
            next[id] = Object.assign({}, current, { availability: hasValue ? "degraded" : "unavailable", freshness: hasValue ? (stale ? "stale" : "current") : "unknown", lastAttempt: now, lastError: failure }, windows);
        });
        providers = next;
    }
    function publish(result) {
        if (!result.ok) { publishFailure(result.error, result.providerId); return; }
        const next = Object.assign({}, providers);
        const ids = result.providerId ? [result.providerId] : providerIds;
        ids.forEach(id => {
            const source = result.data.providers[id];
            const current = provider(id);
            const goodFiveHour = source.fiveHour.status === "ok";
            const goodWeekly = source.weekly.status === "ok";
            const hasMonthly = source.monthly !== undefined;
            const goodMonthly = hasMonthly && source.monthly.status === "ok";
            const retainedFiveHour = current.fiveHour.status === "ok";
            const retainedWeekly = current.weekly.status === "ok";
            const retainedMonthly = current.monthly.status === "ok";
            const hasValue = goodFiveHour || goodWeekly || goodMonthly || retainedFiveHour || retainedWeekly || retainedMonthly;
            const sourceUpdated = (goodFiveHour || goodWeekly || goodMonthly) ? new Date(source.lastUpdated || result.data.observedAt) : current.lastUpdated;
            const stale = hasValue && sourceUpdated instanceof Date && new Date() - sourceUpdated >= 900000;
            const updateTime = (goodFiveHour || goodWeekly || goodMonthly) ? new Date(source.lastUpdated || result.data.observedAt) : null;
            const fiveHourAge = current.fiveHour.lastUpdated instanceof Date ? new Date() - current.fiveHour.lastUpdated : Infinity;
            const weeklyAge = current.weekly.lastUpdated instanceof Date ? new Date() - current.weekly.lastUpdated : Infinity;
            const monthlyAge = current.monthly.lastUpdated instanceof Date ? new Date() - current.monthly.lastUpdated : Infinity;
            const fiveHour = goodFiveHour ? Object.assign({}, source.fiveHour, { freshness: "current", lastUpdated: updateTime }) : (retainedFiveHour ? Object.assign({}, current.fiveHour, { error: errorObject(source.fiveHour.error?.code || "NETWORK_ERROR"), freshness: fiveHourAge >= 900000 ? "stale" : "current" }) : source.fiveHour);
            const weekly = goodWeekly ? Object.assign({}, source.weekly, { freshness: "current", lastUpdated: updateTime }) : (retainedWeekly ? Object.assign({}, current.weekly, { error: errorObject(source.weekly.error?.code || "NETWORK_ERROR"), freshness: weeklyAge >= 900000 ? "stale" : "current" }) : source.weekly);
            const monthly = hasMonthly ? (goodMonthly ? Object.assign({}, source.monthly, { freshness: "current", lastUpdated: updateTime }) : (retainedMonthly ? Object.assign({}, current.monthly, { error: errorObject(source.monthly.error?.code || "NETWORK_ERROR"), freshness: monthlyAge >= 900000 ? "stale" : "current" }) : source.monthly)) : current.monthly;
            const nextProvider = Object.assign({}, current, {
                availability: goodFiveHour && goodWeekly && (!hasMonthly || goodMonthly) ? "available" : (hasValue ? "degraded" : "unavailable"),
                freshness: hasValue ? ((stale || fiveHour.freshness === "stale" || weekly.freshness === "stale" || monthly.freshness === "stale") ? "stale" : "current") : "unknown",
                lastUpdated: sourceUpdated,
                lastAttempt: new Date(),
                lastError: source.error ? errorObject(source.error.code) : null,
                fiveHour: fiveHour,
                weekly: weekly,
                monthly: monthly
            });
            next[id] = nextProvider;
        });
        providers = next;
    }
    function registerConsumer() { consumerCount++; updateAdapter(); }
    function unregisterConsumer() { consumerCount = Math.max(0, consumerCount - 1); updateAdapter(); }
    function updateAdapter() { adapter.active = consumerCount > 0; }
    function refresh() { return adapter.refresh(); }
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
        function onResumed() { root.refresh(); }
    }
    Timer {
        interval: 300000
        repeat: true
        running: root.polling
        onTriggered: root.refresh()
    }
    Timer {
        interval: 60000
        repeat: true
        running: root.polling
        onTriggered: root.markStale()
    }
    function markStale() {
        const now = new Date();
        const next = Object.assign({}, providers);
        providerIds.forEach(id => {
            const current = provider(id);
            if (current.lastUpdated instanceof Date && now - current.lastUpdated >= 900000
                    && (current.fiveHour.status === "ok" || current.weekly.status === "ok")) {
                next[id] = Object.assign({}, current, {
                    availability: "degraded", freshness: "stale",
                    fiveHour: Object.assign({}, current.fiveHour, current.fiveHour.status === "ok" ? { freshness: "stale" } : {}),
                    weekly: Object.assign({}, current.weekly, current.weekly.status === "ok" ? { freshness: "stale" } : {}),
                    monthly: Object.assign({}, current.monthly, current.monthly.status === "ok" ? { freshness: "stale" } : {})
                });
            }
        });
        providers = next;
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
