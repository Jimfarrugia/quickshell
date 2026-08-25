import QtQuick
import Quickshell
import Quickshell.Io
import "../services" as Services

Scope {
    id: root

    property string executable: Quickshell.env("QE_WALLPAPER_EXTERNAL_HELPER")
        || Services.PathsService.shellPath("scripts/promote-external-theme.sh")
    property int timeoutMs: 60000
    property int termGraceMs: 2000
    property string availability: "unknown"
    property string lastError: ""
    readonly property bool running: runner.running

    signal finished(var result)

    function apply(specPath, operationId) {
        if (runner.running || availability !== "available" || !specPath || !operationId)
            return false;
        runner.command = [executable, specPath];
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
            root.lastError = "external wallpaper theme helper is unavailable";
        }
    }

    CommandRunner {
        id: runner
        timeoutMs: root.timeoutMs
        termGraceMs: root.termGraceMs
        maxStdoutBytes: 32768
        maxStderrBytes: 16384
        expectJson: true
        onFinished: raw => {
            const boundaryError = raw.timedOut ? "external wallpaper theme promotion timed out"
                : raw.cancelled ? "external wallpaper theme promotion was cancelled"
                : raw.errorCode || raw.parseError || "external wallpaper theme promotion failed";
            let status = "failed";
            let results = [];
            let failedTargets = [];
            let skippedTargets = 0;
            if (raw.parsed !== null && raw.parsed.results !== undefined) {
                results = raw.parsed.results;
                failedTargets = results.filter(target => target.status === "failed").map(target => target.id);
                skippedTargets = results.filter(target => target.status === "skipped").length;
                status = failedTargets.length === 0 ? "succeeded" : "partial";
            }
            const result = {
                operationId: raw.operationId,
                contractValid: status !== "failed" || raw.exitCode !== 2,
                success: raw.exitCode === 0 || (raw.exitCode === 3 && status === "partial"),
                status,
                results,
                failedTargets,
                skippedTargets,
                error: status === "failed" ? boundaryError : failedTargets.join(", ") || "",
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
            lastError = "QE_WALLPAPER_EXTERNAL_HELPER is not configured";
        }
    }
}