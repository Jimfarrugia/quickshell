pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Validation.mjs" as Validation
import "../integrations" as Integrations

Singleton {
    id: root

    property var defaults: Validation.safeDefaultsManifest
    property bool hasLoaded: false
    property var validationErrors: []
    property var lastError: null
    property var commandAdapter: nativeCommandAdapter
    property string operation: "idle"
    property string operationAction: ""
    property string operationError: ""
    property string operationWarning: ""
    property var operationUpdated: null
    property bool usingFallback: false
    readonly property string defaultTheme: defaults.defaultTheme
    readonly property string availability: !hasLoaded ? "unknown" : (usingFallback ? "degraded" : "available")
    readonly property string freshness: hasLoaded ? "current" : "unknown"
    property var lastUpdated: null

    function load() {
        if (!source.loaded) return;
        applyText(source.text());
    }

    function applyText(text) {
        const parsed = Validation.parseJson(text, "defaults manifest");
        if (!parsed.ok) {
            reject(parsed.errors);
            return false;
        }
        const candidate = Validation.validateDefaultsManifest(parsed.value);
        if (!candidate.ok) {
            reject(candidate.errors);
            return false;
        }
        defaults = candidate.value;
        hasLoaded = true;
        validationErrors = [];
        usingFallback = false;
        lastUpdated = new Date();
        lastError = null;
        return true;
    }

    function reject(errors) {
        validationErrors = errors;
        const retainConfirmed = hasLoaded && !usingFallback;
        lastError = DiagnosticsService.report(
            "DEFAULTS_REJECTED",
            "defaults",
            retainConfirmed
                ? "Authored defaults rejected; retaining last-known-good defaults"
                : "Authored defaults rejected; using safe defaults",
            errors.join("; "),
            true,
            null
        );
        if (!retainConfirmed) defaults = Validation.safeDefaultsManifest;
        hasLoaded = true;
        if (!retainConfirmed) usingFallback = true;
        lastUpdated = new Date();
    }

    function run(action) {
        if (operation === "pending") return false;
        operationAction = action;
        operationError = "";
        operationWarning = "";
        operation = "pending";
        if (!commandAdapter.start(action)) {
            operation = "failed";
            operationError = "Could not start defaults operation";
            return false;
        }
        return true;
    }

    function capture() { return run("capture"); }
    function restore() { return run("restore"); }

    function complete(action, result) {
        if (action !== operationAction) return;
        operationUpdated = new Date();
        if (result.success) {
            operation = "succeeded";
            if (result.stderr && result.stderr.trim().length > 0)
                operationWarning = "Completed with warnings";
        } else {
            operation = "failed";
            operationError = result.timedOut
                ? "Timed out; the final external state may be incomplete"
                : (result.stderr && result.stderr.trim().length > 0
                    ? result.stderr.trim().slice(0, 180) : "Defaults operation failed");
        }
    }

    FileView {
        id: source
        path: PathsService.defaultsManifest
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.load()
        onFileChanged: reload()
        onLoadFailed: error => root.reject([`defaults manifest: failed to read (${error})`])
    }

    Integrations.DefaultsCommandAdapter {
        id: nativeCommandAdapter
        onFinished: (action, result) => root.complete(action, result)
    }

    Component.onCompleted: root.load()
}
