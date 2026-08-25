import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/ExternalTheme.mjs" as ExternalTheme

Scope {
    id: root

    property string executable: Quickshell.env("QE_THEME_SWITCHER")
    property int timeoutMs: 120000
    property int termGraceMs: 2000
    property string availability: "unknown"
    property var lastState: null
    property var lastError: null
    property string requestedThemeId: ""
    property string requestedOperationId: ""
    readonly property bool running: runner.running
    readonly property string statePath: {
        const stateHome = Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`;
        return `${stateHome}/theme-switcher/active-theme.json`;
    }

    signal finished(var result)

    function start(themeId, operationId) {
        if (runner.running || availability !== "available"
                || !ExternalTheme.isExternalThemeId(themeId) || !operationId) return false;
        requestedThemeId = themeId;
        requestedOperationId = operationId;
        runner.command = [executable, "--machine", "--theme", themeId];
        runner.operationId = operationId;
        return runner.start();
    }

    function loadState() {
        if (!stateFile.loaded) return;
        let document = null;
        try {
            document = JSON.parse(stateFile.text());
        } catch (error) {
            lastError = `external theme state is malformed: ${error.message}`;
            return;
        }
        const parsed = ExternalTheme.validateExternalThemeResult(document);
        if (parsed.ok) {
            lastState = parsed.value;
            lastError = null;
        } else {
            lastError = parsed.errors.join("; ");
        }
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
            root.lastError = "theme-switcher executable is unavailable";
        }
    }

    FileView {
        id: stateFile
        path: root.statePath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.loadState()
        onFileChanged: reload()
    }

    CommandRunner {
        id: runner
        timeoutMs: root.timeoutMs
        termGraceMs: root.termGraceMs
        maxStdoutBytes: 131072
        maxStderrBytes: 32768
        expectJson: true
        onFinished: raw => {
            const boundaryError = raw.timedOut ? "external theme apply timed out"
                : raw.cancelled ? "external theme apply was cancelled"
                : raw.errorCode || raw.parseError || "external theme apply failed";
            let validation = { ok: false, errors: [boundaryError], value: null };
            if (raw.parsed !== null)
                validation = ExternalTheme.validateExternalThemeResult(raw.parsed, root.requestedThemeId, raw.exitCode);
            const result = {
                operationId: raw.operationId,
                contractValid: validation.ok,
                status: validation.ok ? validation.value.status : "failed",
                persisted: validation.ok ? validation.value.persisted : false,
                requestedThemeId: root.requestedThemeId,
                targets: validation.ok ? validation.value.results : [],
                error: validation.ok ? validation.value.error : validation.errors.join("; "),
                timedOut: raw.timedOut,
                stderr: raw.stderr
            };
            if (validation.ok && validation.value.persisted)
                root.lastState = validation.value;
            root.lastError = result.error;
            root.finished(result);
        }
    }

    Component.onCompleted: {
        if (!executable) {
            availability = "unavailable";
            lastError = "QE_THEME_SWITCHER is not configured";
        }
    }
}
