import QtQuick
import Quickshell
import Quickshell.Io
import "../services" as Services
import "../utils/ExternalWallpaperTheme.mjs" as ExternalWallpaperTheme

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
            const validation = !raw.timedOut && !raw.cancelled && !raw.errorCode && !raw.parseError
                ? ExternalWallpaperTheme.validateWallpaperExternalResult(raw.parsed, raw.exitCode)
                : { ok: false, errors: [boundaryError], value: null };
            const result = {
                operationId: raw.operationId,
                contractValid: validation.ok,
                success: validation.ok && validation.value.status !== "failed",
                status: validation.ok ? validation.value.status : "failed",
                results: validation.ok ? validation.value.results : [],
                failedTargets: validation.ok ? validation.value.failedTargets : [],
                skippedTargets: validation.ok ? validation.value.skippedTargets : 0,
                error: validation.ok ? validation.value.error : validation.errors.join("; "),
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
