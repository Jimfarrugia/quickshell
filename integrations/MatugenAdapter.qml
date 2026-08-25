import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Matugen.mjs" as Matugen

Scope {
    id: root

    property string executable: Quickshell.env("QE_MATUGEN")
    property int timeoutMs: 120000
    property int termGraceMs: 2000
    property string availability: "unknown"
    property string lastError: ""
    readonly property bool running: runner.running

    signal finished(var result)

    function generate(imagePath, variant, operationId) {
        if (runner.running || availability !== "available" || !imagePath || !operationId)
            return false;
        runner.command = [executable, "image", imagePath, "--json", "hex", "-m", variant, "--prefer", "saturation", "--dry-run"];
        runner.operationId = operationId;
        runner.variant = variant;
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
            root.lastError = "Matugen executable is unavailable";
        }
    }

    CommandRunner {
        id: runner
        property string variant: "dark"
        timeoutMs: root.timeoutMs
        termGraceMs: root.termGraceMs
        maxStdoutBytes: 131072
        maxStderrBytes: 32768
        expectJson: true
        onFinished: raw => {
            let mapped = { ok: false, errors: [], value: null };
            if (raw.timedOut)
                mapped.errors = ["Matugen generation timed out"];
            else if (raw.cancelled)
                mapped.errors = ["Matugen generation was cancelled"];
            else if (raw.parsed !== null)
                mapped = Matugen.mapMatugenTheme(raw.parsed, runner.variant);
            else
                mapped.errors = [raw.parseError || raw.errorCode || "Matugen generation failed"];
            const result = {
                operationId: raw.operationId,
                success: raw.success && mapped.ok,
                theme: mapped.value,
                colors: mapped.ok && mapped.value !== null ? mapped.value.palette : null,
                error: mapped.ok ? "" : mapped.errors.join("; "),
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
            lastError = "QE_MATUGEN is not configured";
        }
    }
}
