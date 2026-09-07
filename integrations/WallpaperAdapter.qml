import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string executable: Quickshell.env("QE_WALLPAPER_HELPER")
    property int timeoutMs: 30000
    property int termGraceMs: 2000
    property string availability: "unknown"
    property string lastError: ""
    readonly property bool running: runner.running

    signal finished(var result)

    function apply(path, operationId) {
        if (runner.running || availability !== "available" || !path || !operationId)
            return false;
        runner.command = [executable, path];
        runner.operationId = operationId;
        return runner.start();
    }

    FileView {
        path: root.executable
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.availability = root.executable ? "available" : "unavailable"
        onFileChanged: reload()
        onLoadFailed: {
            root.availability = "unavailable";
            root.lastError = "wallpaper helper is unavailable";
        }
    }

    CommandRunner {
        id: runner
        timeoutMs: root.timeoutMs
        termGraceMs: root.termGraceMs
        maxStdoutBytes: 16384
        maxStderrBytes: 16384
        expectJson: true
        onFinished: raw => {
            const payload = raw.parsed;
            const contractValid = payload !== null
                && payload.schema === "qe-wallpaper"
                && payload.version === 1
                && ["success", "failed", "unknown", "invalid", "unavailable", "rejected"].indexOf(payload.status) >= 0
                && ["accepted", "none"].indexOf(payload.ipc) >= 0
                && ["promoted", "preserved", "unchanged", "unknown"].indexOf(payload.lkg) >= 0
                && ["requested", "previous", "unknown"].indexOf(payload.live) >= 0
                && typeof payload.requestedSource === "string"
                && (payload.errorCode === null || typeof payload.errorCode === "string")
                && typeof payload.daemonStarted === "boolean";
            const success = raw.success && contractValid
                && payload.status === "success"
                && payload.ipc === "accepted"
                && payload.lkg === "promoted";
            const result = {
                operationId: raw.operationId,
                success,
                confirmation: contractValid && payload.ipc === "accepted"
                    ? "hyprpaper-ipc" : "none",
                live: contractValid ? payload.live : "unknown",
                lkg: contractValid ? payload.lkg : "unknown",
                error: raw.timedOut ? "wallpaper helper timed out"
                    : raw.cancelled ? "wallpaper helper was cancelled"
                    : contractValid && payload.errorCode !== null ? payload.errorCode
                    : raw.parseError || raw.errorCode || "wallpaper helper failed",
                stderr: raw.stderr,
                timedOut: raw.timedOut
            };
            root.lastError = result.error;
            root.finished(result);
        }
    }

    Component.onCompleted: {
        if (!executable) {
            availability = "unavailable";
            lastError = "QE_WALLPAPER_HELPER is not configured";
        }
    }
}
