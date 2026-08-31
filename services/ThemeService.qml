pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Validation.mjs" as Validation

Singleton {
    id: root

    readonly property var emergencyTheme: ({
        schemaVersion: 1,
        id: "emergency",
        name: "Emergency",
        variant: "dark",
        palette: {
            background: "#000000",
            foreground: "#ffffff",
            surface: "#181818",
            surface_variant: "#242424",
            muted: "#b0b0b0",
            primary: "#ffffff",
            secondary: "#b0b0b0",
            link: "#8ab4f8",
            highlight: "#e0c060",
            success: "#70c070",
            error: "#e06060",
            shadow: "#80000000",
            scrim: "#99000000"
        },
        tokens: {
            background: "#000000",
            on_background: "#ffffff",
            surface: "#181818",
            on_surface: "#ffffff",
            surface_variant: "#242424",
            on_surface_variant: "#b0b0b0",
            surface_panel: "#f0000000",
            surface_sidebar: "#000000",
            on_surface_panel: "#ffffff",
            surface_tooltip: "#101010",
            on_surface_tooltip: "#ffffff",
            surface_hover: "#303030",
            surface_pressed: "#404040",
            primary: "#ffffff",
            on_primary: "#000000",
            primary_container: "#303030",
            on_primary_container: "#ffffff",
            secondary: "#b0b0b0",
            on_secondary: "#000000",
            outline: "#707070",
            outline_variant: "#404040",
            focus_ring: "#ffffff",
            on_surface_disabled: "#707070",
            on_surface_placeholder: "#b0b0b0",
            link: "#8ab4f8",
            highlight: "#e0c060",
            on_highlight: "#000000",
            success: "#70c070",
            warning: "#e0c060",
            error: "#e06060",
            shadow: "#80000000",
            scrim: "#99000000",
            charging: "#e0c060"
        }
    })
    property var theme: emergencyTheme
    property string activeThemeId: emergencyTheme.id
    readonly property var catalog: ThemeCatalogService.catalog
    readonly property var validationErrors: ThemeCatalogService.validationErrors
    property var lastError: null
    property string availability: "unknown"
    property string freshness: "unknown"
    property string operation: "idle"
    property var lastUpdated: null
    property var pendingTheme: null
    property string pendingOperationId: ""
    property int nextOperationId: 1
    property bool initialized: false
    property bool stateReady: false
    property bool activeSourceMissing: false
    property var externalAdapter: null
    property string externalOperation: "idle"
    property string externalStatus: "unknown"
    property string externalRequestedThemeId: ""
    property string externalOperationId: ""
    property var externalResults: []
    property var externalLastError: null

    onExternalAdapterChanged: syncExternalState()

    Connections {
        target: DefaultsService
        function onHasLoadedChanged() { root.initializeTheme(); }
    }

    function synchronizeCatalog() {
        if (!ThemeCatalogService.initialized) return;
        const sourceMissing = initialized && activeThemeId !== emergencyTheme.id
            && findTheme(activeThemeId) === null;
        if (sourceMissing && !activeSourceMissing) {
            lastError = DiagnosticsService.report("THEME_ACTIVE_SOURCE_MISSING", "theme", "Active theme source is unavailable", `Retaining last-known-good theme '${activeThemeId}'`, true, null);
        } else if (!sourceMissing && activeSourceMissing && lastError !== null
                   && lastError.code === "THEME_ACTIVE_SOURCE_MISSING") {
            lastError = null;
        }
        activeSourceMissing = sourceMissing;
        availability = sourceMissing && ThemeCatalogService.availability === "available"
            ? "degraded" : ThemeCatalogService.availability;
        freshness = sourceMissing ? "stale" : ThemeCatalogService.freshness;
        lastUpdated = ThemeCatalogService.lastUpdated;
        if (initialized) publishActiveCatalogRevision();
        else initializeTheme();
    }

    function findTheme(id) {
        for (const candidate of catalog) if (candidate.id === id) return candidate;
        return null;
    }

    function initializeTheme() {
        if (initialized || !ThemeCatalogService.initialized || !ConfigService.hasLoaded
                || !DefaultsService.hasLoaded || !stateReady) return;
        let requestedId = DefaultsService.defaultTheme;
        if (stateFile.loaded) {
            const parsed = Validation.parseJson(stateFile.text(), "active theme state");
            if (parsed.ok) {
                const state = Validation.validateThemeState(parsed.value);
                if (state.ok) requestedId = state.value.activeThemeId;
                else reportStateError(state.errors);
            } else reportStateError(parsed.errors);
        }
        const selected = findTheme(requestedId) || findTheme(DefaultsService.defaultTheme);
        if (selected) {
            theme = selected;
            activeThemeId = selected.id;
        } else {
            lastError = DiagnosticsService.report("THEME_FALLBACK", "theme", "Using emergency theme", `No valid configured theme '${requestedId}'`, true, null);
        }
        initialized = true;
        synchronizeCatalog();
    }

    function publishActiveCatalogRevision() {
        if (!initialized || operation === "pending") return;
        const candidate = findTheme(activeThemeId);
        if (!candidate) return;
        theme = candidate;
        lastUpdated = new Date();
    }

    function reportStateError(errors) {
        lastError = DiagnosticsService.report("THEME_STATE_REJECTED", "theme-state", "Invalid active theme state ignored", errors.join("; "), true, null);
    }

    function requestTheme(id) {
        if (!initialized || operation === "pending" || externalOperation === "pending") return false;
        const candidate = findTheme(id);
        if (!candidate) {
            operation = "failed";
            lastError = DiagnosticsService.report("THEME_NOT_FOUND", "theme", "Theme request rejected", `Unknown theme '${id}'`, false, null);
            return false;
        }
        if (id === activeThemeId) return false;
        pendingTheme = candidate;
        pendingOperationId = `theme-${nextOperationId++}`;
        operation = "pending";
        stateFile.setText(JSON.stringify({ schemaVersion: 1, activeThemeId: id }, null, 2) + "\n");
        return true;
    }

    function applyExternalTheme(themeId, operationId, skipGtk = false) {
        return requestExternalTheme(themeId, operationId, skipGtk);
    }

    function commitPendingTheme() {
        if (pendingTheme === null) return;
        const committedThemeId = pendingTheme.id;
        const committedOperationId = pendingOperationId;
        theme = pendingTheme;
        activeThemeId = pendingTheme.id;
        pendingTheme = null;
        operation = "succeeded";
        lastError = null;
        lastUpdated = new Date();
        pendingOperationId = "";
        synchronizeCatalog();
        if (committedThemeId !== "wallpaper")
            requestExternalTheme(committedThemeId, committedOperationId);
    }

    function requestExternalTheme(themeId, operationId, skipGtk = false) {
        if (externalOperation === "pending") return false;
        externalRequestedThemeId = themeId;
        externalOperationId = operationId;
        externalResults = [];
        externalLastError = null;
        if (externalAdapter === null || externalAdapter.availability !== "available") {
            externalOperation = "failed";
            externalStatus = "unavailable";
            externalLastError = "external theme switcher is unavailable";
            return;
        }
        externalOperation = "pending";
        externalStatus = "pending";
        if (!externalAdapter.start(themeId, operationId, skipGtk)) {
            externalOperation = "failed";
            externalStatus = "failed";
            externalLastError = "external theme request could not start";
            return false;
        }
        return true;
    }

    function handleExternalResult(result) {
        if (result.operationId !== externalOperationId) return;
        externalResults = result.targets;
        externalLastError = result.error;
        externalStatus = result.status;
        externalOperation = result.contractValid ? "succeeded" : "failed";
        if (!result.contractValid)
            DiagnosticsService.report("EXTERNAL_THEME_CONTRACT_REJECTED", "external-theme", "External theme result rejected", result.error, true, result.operationId);
        else if (result.status !== "success")
            DiagnosticsService.report("EXTERNAL_THEME_PARTIAL", "external-theme", "External theme apply did not fully succeed", result.error || result.status, true, result.operationId);
    }

    function syncExternalState() {
        if (externalAdapter === null || externalOperation === "pending" || externalAdapter.lastState === null) return;
        externalRequestedThemeId = externalAdapter.lastState.requestedTheme;
        externalStatus = externalAdapter.lastState.status;
        externalResults = externalAdapter.lastState.results;
    }

    function failPendingTheme(error) {
        if (pendingTheme === null) return;
        lastError = DiagnosticsService.report("THEME_STATE_WRITE_FAILED", "theme-state", "Theme request failed; retaining confirmed theme", `${error}`, true, pendingOperationId);
        pendingTheme = null;
        operation = "failed";
        pendingOperationId = "";
        publishActiveCatalogRevision();
    }

    FileView {
        id: stateFile
        path: PathsService.activeThemeState
        blockLoading: true
        atomicWrites: true
        printErrors: false
        onLoaded: {
            root.stateReady = true;
            root.initializeTheme();
        }
        onLoadFailed: {
            root.stateReady = true;
            root.initializeTheme();
        }
        onSaved: root.commitPendingTheme()
        onSaveFailed: error => root.failPendingTheme(error)
    }

    Connections {
        target: ConfigService
        function onHasLoadedChanged() { root.initializeTheme(); }
    }

    Connections {
        target: ThemeCatalogService
        function onCatalogChanged() { root.synchronizeCatalog(); }
        function onInitializedChanged() { root.synchronizeCatalog(); }
    }

    Connections {
        target: root.externalAdapter
        ignoreUnknownSignals: true
        function onFinished(result) { root.handleExternalResult(result); }
        function onLastStateChanged() { root.syncExternalState(); }
    }

    Component.onCompleted: root.synchronizeCatalog()
}
