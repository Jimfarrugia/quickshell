import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/AiQuota.mjs" as AiQuota

QtObject {
    id: root
    property bool active: false
    property string helperPath: Quickshell.shellPath("scripts/qe-ai-quota.py")
    property var providerIds: ["openai", "opencode"]
    property var nextAllowedAt: ({ openai: 0, opencode: 0 })
    property var failureStreak: ({ openai: 0, opencode: 0 })
    property var backoffCodes: ({ openai: "", opencode: "" })
    property var cycleProviders: []
    property bool cycleActive: false
    property string cycleReason: ""
    property string queuedReason: ""
    property string pendingProvider: ""
    property bool requestInFlight: false
    property bool sleeping: false
    property string cancellationReason: ""
    property bool busy: false
    property bool wakeWatcherEnabled: true
    property bool wakeWatcherDesired: false
    property var runner: CommandRunner {
        command: ["/usr/bin/python3", root.helperPath]
        expectJson: true
        timeoutMs: 20000
        maxStdoutBytes: 262144
        maxStderrBytes: 4096
    }
    signal refreshed(var result)
    signal resumed()

    function consumeSleepLine(line) {
        if (typeof line !== "string") return;
        const value = line.trim();
        if (value === "boolean true") {
            if (sleeping) return;
            sleeping = true;
            cycleProviders = [];
            cycleActive = false;
            if (requestInFlight) {
                cancellationReason = "sleep";
                runner.cancel();
            } else {
                pendingProvider = "";
                updateBusy();
            }
        } else if (value === "boolean false" && sleeping) {
            sleeping = false;
            resumed();
        }
    }
    function updateBusy() {
        busy = cycleActive || requestInFlight || queuedReason !== "";
    }
    function queueReason(reason) {
        if (reason === "poll" && (queuedReason !== "" || cycleActive)) return;
        if (queuedReason !== "" && reasonPriority(reason) <= reasonPriority(queuedReason)) return;
        queuedReason = reason;
        updateBusy();
    }
    function reasonPriority(reason) {
        return { poll: 0, startup: 1, resume: 2, manual: 3 }[reason] || 0;
    }
    function requestCycle(reason) {
        reason = reason || "poll";
        if (!active) return false;
        if (sleeping || requestInFlight || cycleActive) {
            queueReason(reason);
            return true;
        }
        if (queuedReason !== "") {
            if (reasonPriority(queuedReason) > reasonPriority(reason)) reason = queuedReason;
            queuedReason = "";
        }
        cycleReason = reason;
        cycleProviders = providerIds.slice();
        cycleActive = true;
        continueCurrentCycle();
        return true;
    }
    function refresh() { return requestCycle("manual"); }
    function isEligible(id) {
        if (Date.now() >= nextAllowedAt[id]) return true;
        return cycleReason === "manual"
            && (backoffCodes[id] === "TIMEOUT" || backoffCodes[id] === "NETWORK_ERROR");
    }
    function continueCurrentCycle() {
        if (!active || sleeping || requestInFlight || !cycleActive) {
            updateBusy();
            return;
        }
        while (cycleProviders.length > 0) {
            const id = cycleProviders.shift();
            if (!isEligible(id)) continue;
            pendingProvider = id;
            requestInFlight = true;
            runner.command = ["/usr/bin/python3", root.helperPath, "--provider", id];
            if (runner.start()) {
                updateBusy();
                return;
            }
            requestInFlight = false;
            pendingProvider = "";
            refreshed({ ok: false, error: "FAILED_TO_START", providerId: id });
            Qt.callLater(() => root.continueCurrentCycle());
            return;
        }
        cycleProviders = [];
        cycleActive = false;
        cycleReason = "";
        pendingProvider = "";
        updateBusy();
        drainQueuedCycle();
    }
    function drainQueuedCycle() {
        if (!active || sleeping || requestInFlight || cycleActive || queuedReason === "") return;
        const reason = queuedReason;
        queuedReason = "";
        requestCycle(reason);
    }
    function clearInactiveState() {
        queuedReason = "";
        cycleProviders = [];
        cycleActive = false;
        cycleReason = "";
        pendingProvider = "";
        if (!requestInFlight) updateBusy();
    }
    function completeCancellation() {
        const reason = cancellationReason;
        cancellationReason = "";
        requestInFlight = false;
        pendingProvider = "";
        if (reason === "deactivate") {
            clearInactiveState();
            return;
        }
        cycleProviders = [];
        cycleActive = false;
        cycleReason = "";
        updateBusy();
        drainQueuedCycle();
    }
    function backoff(id, code, retryAfter) {
        const transient = ["TIMEOUT", "NETWORK_ERROR", "RATE_LIMITED"].indexOf(code) !== -1;
        const next = Object.assign({}, nextAllowedAt);
        const streak = Object.assign({}, failureStreak);
        const codes = Object.assign({}, backoffCodes);
        if (!transient) {
            next[id] = 0;
            streak[id] = 0;
            codes[id] = "";
        } else {
            streak[id] = Math.min(3, (streak[id] || 0) + 1);
            const delay = retryAfter !== null && retryAfter !== undefined
                ? retryAfter * 1000 : [600000, 1200000, 1800000][streak[id] - 1];
            next[id] = Date.now() + delay;
            codes[id] = code;
        }
        nextAllowedAt = next;
        failureStreak = streak;
        backoffCodes = codes;
    }
    function failureCode(result) {
        return result.timedOut ? "TIMEOUT" : (result.parseError ? "INVALID_RESPONSE" : "NETWORK_ERROR");
    }
    function publish(result) {
        if (!requestInFlight) return;
        if (result.cancelled) {
            if (cancellationReason !== "") completeCancellation();
            return;
        }
        const id = pendingProvider;
        if (!id) return;
        requestInFlight = false;
        pendingProvider = "";
        if (result.success && result.parsed !== null) {
            const checked = AiQuota.validateQuotaDocument(result.parsed, [id]);
            if (checked.ok) {
                const sourceError = checked.value.providers[id].error;
                root.backoff(id, sourceError ? sourceError.code : null,
                    sourceError ? sourceError.retryAfterSeconds : null);
                refreshed({ ok: true, data: checked.value, providerId: id });
                Qt.callLater(() => root.continueCurrentCycle());
                return;
            }
        }
        const code = failureCode(result);
        root.backoff(id, code, null);
        refreshed({ ok: false, error: code, providerId: id });
        Qt.callLater(() => root.continueCurrentCycle());
    }
    onActiveChanged: {
        wakeWatcherDesired = active && wakeWatcherEnabled;
        if (active) requestCycle("startup");
        else {
            sleeping = false;
            queuedReason = "";
            cancellationReason = requestInFlight ? "deactivate" : "";
            if (requestInFlight) runner.cancel();
            else clearInactiveState();
        }
    }
    property Process wakeWatcher: Process {
        command: ["dbus-monitor", "--system",
            "type='signal',sender='org.freedesktop.login1',path='/org/freedesktop/login1',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]
        running: root.wakeWatcherDesired
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.consumeSleepLine(data)
        }
        onExited: {
            if (root.active && root.wakeWatcherEnabled) {
                root.wakeWatcherDesired = false;
                wakeWatcherRestart.restart();
            }
        }
    }
    property Timer wakeWatcherRestart: Timer {
        interval: 5000
        repeat: false
        onTriggered: root.wakeWatcherDesired = root.active && root.wakeWatcherEnabled
    }
    onWakeWatcherEnabledChanged: wakeWatcherDesired = active && wakeWatcherEnabled
    property Connections runnerConnection: Connections {
        target: root.runner
        function onFinished(result) { root.publish(result); }
    }
}
