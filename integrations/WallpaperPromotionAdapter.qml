import QtQuick
import Quickshell
import Quickshell.Io
import "../services" as Services

Scope {
    id: root

    property string executable: Quickshell.env("QE_WALLPAPER_PROMOTER")
        || Services.PathsService.shellPath("scripts/promote-wallpaper-theme.sh")
    property int timeoutMs: 30000
    property int termGraceMs: 2000
    property string availability: "unknown"
    property string lastError: ""
    readonly property bool running: runner.running

    signal finished(var result)

    function promote(stagedPath, targetPath, operationId) {
        if (runner.running || availability !== "available" || !stagedPath || !targetPath || !operationId)
            return false;
        runner.command = [executable, stagedPath, targetPath];
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
            root.lastError = "wallpaper theme promoter is unavailable";
        }
    }

    CommandRunner {
        id: runner
        timeoutMs: root.timeoutMs
        termGraceMs: root.termGraceMs
        maxStdoutBytes: 8192
        maxStderrBytes: 16384
        expectJson: false
        onFinished: raw => {
            const result = {
                operationId: raw.operationId,
                success: raw.success,
                error: raw.timedOut ? "wallpaper theme promotion timed out"
                    : raw.errorCode || (raw.exitCode === 0 ? "" : "wallpaper theme promotion failed"),
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
            lastError = "QE_WALLPAPER_PROMOTER is not configured";
        }
    }
}
