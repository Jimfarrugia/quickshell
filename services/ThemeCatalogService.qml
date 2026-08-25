pragma Singleton

import QtQuick
import QtQml.Models
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../utils/Validation.mjs" as Validation

Singleton {
    id: root

    property var catalog: []
    property var validationErrors: []
    property var lastError: null
    property string availability: "unknown"
    property string freshness: "unknown"
    property string operation: "idle"
    property var lastUpdated: null
    property bool initialized: false
    property string reportedValidationSignature: ""

    function parseTheme(view, path) {
        if (!view.loaded) return { value: null, errors: [`${path}: file is not loaded`] };
        const parsed = Validation.parseJson(view.text(), path);
        if (!parsed.ok) return { value: null, errors: parsed.errors };
        const result = Validation.validateTheme(parsed.value);
        if (!result.ok)
            return { value: null, errors: result.errors.map(error => `${path}: ${error}`) };
        return { value: result.value, errors: [] };
    }

    function themeFilesSettled() {
        if (themeFolder.status !== FolderListModel.Ready || themeFiles.count !== themeFolder.count
                || !generatedThemeFile.settled)
            return false;
        for (let index = 0; index < themeFiles.count; index++) {
            const file = themeFiles.objectAt(index);
            if (file === null || !file.settled) return false;
        }
        return true;
    }

    function rebuildCatalog() {
        if (!themeFilesSettled()) return;
        let errors = [];
        const entries = [];
        for (let index = 0; index < themeFiles.count; index++) {
            const file = themeFiles.objectAt(index);
            errors = errors.concat(file.errors);
            if (file.candidate !== null)
                entries.push({ path: file.relativePath, theme: file.candidate });
        }
        errors = errors.concat(generatedThemeFile.errors);
        if (generatedThemeFile.candidate !== null)
            entries.push({ path: generatedThemeFile.relativePath, theme: generatedThemeFile.candidate });
        entries.sort((first, second) => first.path.localeCompare(second.path));
        const idCounts = new Map();
        for (const entry of entries)
            idCounts.set(entry.theme.id, (idCounts.get(entry.theme.id) || 0) + 1);
        const candidates = entries.filter(entry => {
            if (idCounts.get(entry.theme.id) > 1) {
                errors.push(`${entry.path}: duplicate theme ID '${entry.theme.id}'`);
                return false;
            }
            return true;
        }).map(entry => entry.theme);
        candidates.sort((first, second) => first.name.localeCompare(second.name) || first.id.localeCompare(second.id));

        validationErrors = errors;
        const signature = errors.join("\n");
        if (signature !== reportedValidationSignature) {
            let latestError = null;
            for (const detail of errors)
                latestError = DiagnosticsService.report("THEME_REJECTED", "theme-catalog", "Theme excluded from catalog", detail, true, null);
            lastError = latestError;
            reportedValidationSignature = signature;
        }
        availability = candidates.length > 0 ? (errors.length > 0 ? "degraded" : "available") : "unavailable";
        freshness = "current";
        lastUpdated = new Date();
        catalog = candidates;
        initialized = true;
    }

    FolderListModel {
        id: themeFolder
        folder: `file://${PathsService.themeDirectory}/`
        nameFilters: ["*.json"]
        showDirs: false
        showFiles: true
        showHidden: false
        showOnlyReadable: true
        sortField: FolderListModel.Name
        sortCaseSensitive: true
        onStatusChanged: Qt.callLater(root.rebuildCatalog)
        onCountChanged: Qt.callLater(root.rebuildCatalog)
    }

    Instantiator {
        id: themeFiles
        model: themeFolder
        delegate: FileView {
            required property string fileName
            readonly property string relativePath: `themes/${fileName}`
            readonly property bool ignored: fileName === "schema.json"
            property var candidate: null
            property var errors: []
            property bool settled: false

            path: PathsService.shellPath(relativePath)
            blockLoading: true
            watchChanges: true
            printErrors: false
            onLoaded: {
                if (ignored) {
                    candidate = null;
                    errors = [];
                    settled = true;
                    root.rebuildCatalog();
                    return;
                }
                const result = root.parseTheme(this, relativePath);
                candidate = result.value;
                errors = result.errors;
                settled = true;
                root.rebuildCatalog();
            }
            onFileChanged: {
                if (ignored) return;
                settled = false;
                reload();
                text();
            }
            onLoadFailed: error => {
                candidate = null;
                errors = [`${relativePath}: file could not be read (${error})`];
                settled = true;
                root.rebuildCatalog();
            }
        }
        onObjectAdded: Qt.callLater(root.rebuildCatalog)
        onObjectRemoved: Qt.callLater(root.rebuildCatalog)
    }

    FileView {
        id: generatedThemeFile
        readonly property string relativePath: "generated/Wallpaper.json"
        property var candidate: null
        property var errors: []
        property bool settled: false

        path: PathsService.generatedThemePath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: {
            const result = root.parseTheme(this, relativePath);
            candidate = result.value;
            errors = result.errors;
            settled = true;
            root.rebuildCatalog();
        }
        onFileChanged: {
            settled = false;
            reload();
            text();
        }
        onLoadFailed: {
            candidate = null;
            errors = [];
            settled = true;
            root.rebuildCatalog();
        }
    }

    Component.onCompleted: rebuildCatalog()
}
