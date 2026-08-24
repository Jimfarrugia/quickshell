pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Validation.mjs" as Validation

Singleton {
    id: root

    property var config: Validation.defaultConfig
    property bool hasLoaded: false
    property var validationErrors: []
    property var lastError: null
    property bool usingFallback: false
    readonly property string availability: !hasLoaded ? "unknown" : (usingFallback ? "degraded" : "available")
    readonly property string freshness: hasLoaded ? "current" : "unknown"
    readonly property string operation: "idle"
    property var lastUpdated: null

    function load() {
        if (!source.loaded) return;
        applyText(source.text());
    }

    function applyText(text) {
        const parsed = Validation.parseJson(text, "config");
        if (!parsed.ok) {
            reject(parsed.errors);
            return false;
        }
        const candidate = Validation.validateConfig(parsed.value);
        if (!candidate.ok) {
            reject(candidate.errors);
            return false;
        }
        config = candidate.value;
        hasLoaded = true;
        validationErrors = candidate.errors;
        usingFallback = candidate.errors.length > 0;
        lastUpdated = new Date();
        lastError = null;
        for (const detail of candidate.errors)
            DiagnosticsService.report("CONFIG_FIELD_FALLBACK", "config", "Invalid field used its safe default", detail, false, null);
        return true;
    }

    function reject(errors) {
        validationErrors = errors;
        lastError = DiagnosticsService.report(
            "CONFIG_REJECTED",
            "config",
            hasLoaded ? "Configuration update rejected; retaining last-known-good configuration" : "Configuration rejected; using safe defaults",
            errors.join("; "),
            true,
            null
        );
        usingFallback = true;
        if (!hasLoaded) {
            config = Validation.defaultConfig;
            hasLoaded = true;
            lastUpdated = new Date();
        }
    }

    FileView {
        id: source
        path: PathsService.configFile
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.load()
        onFileChanged: reload()
        onLoadFailed: error => root.reject([`config: failed to read (${error})`])
    }

    Component.onCompleted: root.load()
}
