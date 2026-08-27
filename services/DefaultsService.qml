pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Validation.mjs" as Validation

Singleton {
    id: root

    property var defaults: Validation.safeDefaultsManifest
    property bool hasLoaded: false
    property var validationErrors: []
    property var lastError: null
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

    Component.onCompleted: root.load()
}
