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
        tokens: {
            background: "#000000",
            on_background: "#ffffff",
            surface: "#181818",
            on_surface: "#ffffff",
            surface_variant: "#242424",
            on_surface_variant: "#b0b0b0",
            surface_panel: "#f0000000",
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
            charging: "#e0c060",
            warning: "#e0c060",
            error: "#e06060",
            shadow: "#80000000",
            scrim: "#99000000"
        }
    })
    property var theme: emergencyTheme
    property string activeThemeId: emergencyTheme.id
    property var catalog: []
    property var validationErrors: []
    property var lastError: null
    property string availability: "unknown"
    property string freshness: "unknown"
    property string operation: "idle"
    property var lastUpdated: null
    property var pendingTheme: null
    property string pendingOperationId: ""
    property int nextOperationId: 1
    property bool initialized: false
    property bool poimandresFailed: false
    property bool gruvboxFailed: false
    property bool stateReady: false

    function parseTheme(view, path) {
        if (!view.loaded) return null;
        const parsed = Validation.parseJson(view.text(), path);
        if (!parsed.ok) {
            validationErrors = validationErrors.concat(parsed.errors);
            return null;
        }
        const result = Validation.validateTheme(parsed.value);
        if (!result.ok) {
            validationErrors = validationErrors.concat(result.errors.map(error => `${path}: ${error}`));
            return null;
        }
        return result.value;
    }

    function rebuildCatalog() {
        if (!(poimandresFile.loaded || poimandresFailed) || !(gruvboxFile.loaded || gruvboxFailed)) return;
        validationErrors = [];
        const candidates = [
            parseTheme(poimandresFile, "themes/poimandres.json"),
            parseTheme(gruvboxFile, "themes/gruvbox.json")
        ].filter(candidate => candidate !== null);
        const ids = new Set();
        catalog = candidates.filter(candidate => {
            if (ids.has(candidate.id)) {
                validationErrors = validationErrors.concat([`duplicate theme ID '${candidate.id}'`]);
                return false;
            }
            ids.add(candidate.id);
            return true;
        });
        for (const detail of validationErrors)
            DiagnosticsService.report("THEME_REJECTED", "theme", "Theme excluded from catalog", detail, true, null);
        availability = catalog.length > 0 ? (validationErrors.length > 0 ? "degraded" : "available") : "unavailable";
        freshness = "current";
        lastUpdated = new Date();
        initializeTheme();
    }

    function findTheme(id) {
        for (const candidate of catalog) if (candidate.id === id) return candidate;
        return null;
    }

    function initializeTheme() {
        if (initialized || catalog.length === 0 || !ConfigService.hasLoaded || !stateReady) return;
        let requestedId = ConfigService.config.defaultTheme;
        if (stateFile.loaded) {
            const parsed = Validation.parseJson(stateFile.text(), "active theme state");
            if (parsed.ok) {
                const state = Validation.validateThemeState(parsed.value);
                if (state.ok) requestedId = state.value.activeThemeId;
                else reportStateError(state.errors);
            } else reportStateError(parsed.errors);
        }
        const selected = findTheme(requestedId) || findTheme(ConfigService.config.defaultTheme);
        if (selected) {
            theme = selected;
            activeThemeId = selected.id;
        } else {
            lastError = DiagnosticsService.report("THEME_FALLBACK", "theme", "Using emergency theme", `No valid configured theme '${requestedId}'`, true, null);
        }
        initialized = true;
    }

    function reportStateError(errors) {
        lastError = DiagnosticsService.report("THEME_STATE_REJECTED", "theme-state", "Invalid active theme state ignored", errors.join("; "), true, null);
    }

    function themeLoadFailed(name, error) {
        if (name === "poimandres") poimandresFailed = true;
        else gruvboxFailed = true;
        DiagnosticsService.report("THEME_READ_FAILED", "theme", "Theme file could not be read", `themes/${name}.json (${error})`, true, null);
        rebuildCatalog();
    }

    function requestTheme(id) {
        if (!initialized || operation === "pending") return false;
        const candidate = findTheme(id);
        if (!candidate) {
            operation = "failed";
            lastError = DiagnosticsService.report("THEME_NOT_FOUND", "theme", "Theme request rejected", `Unknown theme '${id}'`, false, null);
            return false;
        }
        pendingTheme = candidate;
        pendingOperationId = `theme-${nextOperationId++}`;
        operation = "pending";
        stateFile.setText(JSON.stringify({ schemaVersion: 1, activeThemeId: id }, null, 2) + "\n");
        return true;
    }

    function commitPendingTheme() {
        if (pendingTheme === null) return;
        theme = pendingTheme;
        activeThemeId = pendingTheme.id;
        pendingTheme = null;
        operation = "succeeded";
        lastError = null;
        lastUpdated = new Date();
        pendingOperationId = "";
    }

    function failPendingTheme(error) {
        if (pendingTheme === null) return;
        lastError = DiagnosticsService.report("THEME_STATE_WRITE_FAILED", "theme-state", "Theme request failed; retaining confirmed theme", `${error}`, true, pendingOperationId);
        pendingTheme = null;
        operation = "failed";
        pendingOperationId = "";
    }

    FileView {
        id: poimandresFile
        path: PathsService.shellPath("themes/poimandres.json")
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: {
            root.poimandresFailed = false;
            root.rebuildCatalog();
        }
        onFileChanged: reload()
        onLoadFailed: error => root.themeLoadFailed("poimandres", error)
    }

    FileView {
        id: gruvboxFile
        path: PathsService.shellPath("themes/gruvbox.json")
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: {
            root.gruvboxFailed = false;
            root.rebuildCatalog();
        }
        onFileChanged: reload()
        onLoadFailed: error => root.themeLoadFailed("gruvbox", error)
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

    Component.onCompleted: root.rebuildCatalog()
}
