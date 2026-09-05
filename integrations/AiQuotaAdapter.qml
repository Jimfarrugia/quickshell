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
    property var cycleProviders: []
    property bool cycleActive: false
    property string pendingProvider: ""
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
        if (typeof line === "string" && line.trim() === "boolean false") resumed();
    }

    function refresh() {
        if (!active || runner.running) {
            if (!active) {
                busy = false;
                cycleProviders = [];
                cycleActive = false;
                pendingProvider = "";
            }
            return false;
        }
        if (!cycleActive) {
            cycleProviders = providerIds.slice();
            cycleActive = true;
        }
        while (cycleProviders.length > 0) {
            const id = cycleProviders.shift();
            if (Date.now() < nextAllowedAt[id]) continue;
            pendingProvider = id;
            runner.command = ["/usr/bin/python3", root.helperPath, "--provider", id];
            if (runner.start()) {
                busy = true;
                return true;
            }
            pendingProvider = "";
            busy = false;
            return false;
        }
        cycleProviders = [];
        cycleActive = false;
        pendingProvider = "";
        busy = false;
        return false;
    }
    function backoff(id, code, retryAfter) {
        const transient = ["TIMEOUT", "NETWORK_ERROR", "RATE_LIMITED"].indexOf(code) !== -1;
        const next = Object.assign({}, nextAllowedAt);
        const streak = Object.assign({}, failureStreak);
        if (!transient) { next[id] = 0; streak[id] = 0; }
        else {
            streak[id] = Math.min(3, (streak[id] || 0) + 1);
            const delay = retryAfter !== null && retryAfter !== undefined
                ? retryAfter * 1000 : [600000, 1200000, 1800000][streak[id] - 1];
            next[id] = Date.now() + delay;
        }
        nextAllowedAt = next;
        failureStreak = streak;
    }
    function failureCode(result) { return result.timedOut ? "TIMEOUT" : (result.parseError ? "INVALID_RESPONSE" : "NETWORK_ERROR"); }
    function publish(result) {
        if (result.cancelled) {
            busy = false;
            cycleProviders = [];
            cycleActive = false;
            pendingProvider = "";
            return;
        }
        const id = pendingProvider;
        if (!id) return;
        if (result.success && result.parsed !== null) {
            const checked = AiQuota.validateQuotaDocument(result.parsed, [id]);
            if (checked.ok) {
                const sourceError = checked.value.providers[id].error;
                root.backoff(id, sourceError ? sourceError.code : null, sourceError ? sourceError.retryAfterSeconds : null);
                refreshed({ ok: true, data: checked.value, providerId: id });
                Qt.callLater(() => root.refresh());
                return;
            }
        }
        const code = failureCode(result);
        root.backoff(id, code, null);
        refreshed({ ok: false, error: code, providerId: id });
        Qt.callLater(() => root.refresh());
    }
    onActiveChanged: {
        wakeWatcherDesired = active && wakeWatcherEnabled;
        if (active) refresh();
        else {
            if (runner.running) runner.cancel();
            busy = false;
            cycleProviders = [];
            cycleActive = false;
            pendingProvider = "";
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
