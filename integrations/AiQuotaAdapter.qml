import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/AiQuota.mjs" as AiQuota
import "../utils/AiQuotaScheduler.mjs" as Scheduler
import "../utils/Validation.mjs" as Validation

// Runs the AI quota helper for the refresh scheduler. This adapter owns the
// scheduler state, including per-provider backoff; the transitions are pure
// (utils/AiQuotaScheduler.mjs) and this object only performs their effects.
QtObject {
    id: root
    property bool active: false
    property string helperPath: Quickshell.shellPath("scripts/qe-ai-quota.py")
    readonly property var helperCommand: ["/usr/bin/python3", root.helperPath]
    property var schedule: Scheduler.initialState(AiQuota.providerIds)
    readonly property bool busy: Scheduler.isBusy(schedule)
    readonly property string operation: Scheduler.operation(schedule)
    readonly property bool sleeping: schedule.sleeping
    property bool wakeWatcherEnabled: true
    property bool wakeWatcherDesired: false
    property var runner: CommandRunner {
        command: root.helperCommand
        expectJson: true
        timeoutMs: 20000
        maxStdoutBytes: 262144
        maxStderrBytes: 4096
    }
    signal refreshed(var result)
    signal resumed()

    // Effects may dispatch further events (a failed start, the service's resume
    // check); the new state is committed before any effect runs.
    function dispatch(event) {
        const next = Scheduler.reduce(schedule, event, Date.now());
        schedule = next.state;
        for (const effect of next.effects) perform(effect);
        return next.accepted;
    }
    function perform(effect) {
        if (effect.type === "start") {
            runner.command = Array.from(root.helperCommand).concat(["--provider", effect.providerId]);
            if (!runner.start()) dispatch({ type: "startFailed", providerId: effect.providerId });
        } else if (effect.type === "cancel") {
            runner.cancel();
        } else if (effect.type === "publish") {
            refreshed(effect.result);
        } else if (effect.type === "resumed") {
            resumed();
        }
    }

    function requestCycle(reason) { return dispatch({ type: "request", reason: reason || "poll" }); }
    function refresh() { return requestCycle("manual"); }

    function consumeSleepLine(line) {
        if (typeof line !== "string") return;
        const value = line.trim();
        if (value === "boolean true") dispatch({ type: "sleep" });
        else if (value === "boolean false") dispatch({ type: "wake" });
    }
    function publish(result) {
        const parsed = result.parsed;
        dispatch({
            type: "finished",
            result: { cancelled: result.cancelled === true, success: result.success === true,
                timedOut: result.timedOut === true, parseError: result.parseError === true },
            document: result.success === true && parsed !== null && parsed !== undefined
                ? Validation.toPlainJson(parsed) : null
        });
    }
    onActiveChanged: {
        wakeWatcherDesired = active && wakeWatcherEnabled;
        dispatch({ type: active ? "activate" : "deactivate" });
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
