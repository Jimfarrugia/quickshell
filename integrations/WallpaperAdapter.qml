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
        expectJson: false
        onFinished: raw => {
            const result = {
                operationId: raw.operationId,
                success: raw.success,
                confirmation: raw.success ? "hyprpaper-ipc" : "none",
                error: raw.timedOut ? "wallpaper helper timed out"
                    : raw.errorCode || (raw.exitCode === 0 ? "" : "wallpaper helper failed"),
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
