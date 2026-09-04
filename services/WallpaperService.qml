pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../utils/Wallpaper.mjs" as Wallpaper
import "../utils/ExternalWallpaperTheme.mjs" as ExternalWallpaperTheme

Singleton {
    id: root

    readonly property string wallpaperRoot: PathsService.wallpaperRoot
    readonly property var catalogModel: thumbnailModel
    readonly property string wallpaperDirectory: `${wallpaperRoot}/themes/${ThemeService.activeThemeId}`
    readonly property string cacheDirectory: PathsService.cachePath(`wallpaper/${wallpaperDirectory.split("/").pop()}`)
    readonly property string cacheManifestPath: `${cacheDirectory}/manifest`
    property string selectedPath: ""
    property string requestedPath: ""
    property string appliedPath: ""
    property string availability: "unknown"
    property string freshness: "unknown"
    property string operation: "idle"
    readonly property bool wallpaperDirectoryReady: wallpaperFiles.status === FolderListModel.Ready
    readonly property int wallpaperDirectoryCount: wallpaperFiles.count
    property string generationStatus: "idle"
    property string cacheStatus: "idle"
    property string lastError: ""
    property bool stateReady: false
    property bool initialized: false
    property var wallpaperAdapter: null
    property var matugenAdapter: null
    property var cacheAdapter: null
    property var promotionAdapter: null
    property var externalThemeAdapter: null
    property string pendingExternalSpecPath: ""
    property string pendingExternalId: ""
    property string pendingExternalColors: ""
    property string externalThemeStatus: "idle"
    property var externalThemeResults: []
    property var externalThemeFailedTargets: []
    property string pendingPath: ""
    property string pendingOperationId: ""
    property string pendingGenerationPath: ""
    property string pendingGenerationId: ""
    property string pendingGenerationStagePath: ""
    property string generationQueuedPath: ""
    property string pendingCacheId: ""
    property int nextOperationId: 1

    signal cacheUpdated()

    function refreshAvailability() {
        availability = wallpaperAdapter === null ? "unknown" : wallpaperAdapter.availability;
    }

    function validPath(path) {
        return path === PathsService.defaultWallpaperImage
            || Wallpaper.isWallpaperPath(path, wallpaperRoot);
    }

    function requestDefaultWallpaper() {
        return requestWallpaper(PathsService.defaultWallpaperImage);
    }

    function requestRandomWallpaper() {
        if (wallpaperFiles.status !== FolderListModel.Ready || wallpaperFiles.count === 0) {
            lastError = "no wallpapers are available for the active theme";
            operation = "failed";
            return false;
        }
        const index = Math.floor(Math.random() * wallpaperFiles.count);
        return requestWallpaper(wallpaperFiles.get(index, "filePath"));
    }

    function requestWallpaper(path) {
        if (!initialized || operation === "pending" || !validPath(path)) {
            lastError = !validPath(path) ? "wallpaper path is outside the configured wallpaper root" : "wallpaper operation is already pending";
            operation = "failed";
            return false;
        }
        if (wallpaperAdapter === null || wallpaperAdapter.availability !== "available") {
            lastError = "wallpaper helper is unavailable";
            operation = "failed";
            return false;
        }
        pendingPath = path;
        pendingOperationId = `wallpaper-${nextOperationId++}`;
        requestedPath = path;
        operation = "pending";
        if (!wallpaperAdapter.apply(path, pendingOperationId)) {
            lastError = "wallpaper request could not start";
            pendingPath = "";
            pendingOperationId = "";
            operation = "failed";
            return false;
        }
        return true;
    }

    function requestGeneration(path) {
        const sourcePath = path || selectedPath;
        if (!initialized || !validPath(sourcePath)) {
            if (generationStatus !== "pending") {
                generationStatus = "failed";
                lastError = "wallpaper generation requires a path inside the configured wallpaper root";
            }
            return false;
        }
        if (generationStatus === "pending") {
            if (sourcePath !== pendingGenerationPath && sourcePath !== generationQueuedPath)
                generationQueuedPath = sourcePath;
            return true;
        }
        if (matugenAdapter === null || matugenAdapter.availability !== "available"
                || promotionAdapter === null || promotionAdapter.availability !== "available") {
            generationStatus = "unavailable";
            return false;
        }
        pendingGenerationPath = sourcePath;
        pendingGenerationId = `matugen-${nextOperationId++}`;
        generationStatus = "pending";
        if (!matugenAdapter.generate(sourcePath, currentVariant(), pendingGenerationId)) {
            generationStatus = "failed";
            lastError = "Matugen generation could not start";
            pendingGenerationPath = "";
            pendingGenerationId = "";
            return false;
        }
        return true;
    }

    function syncCache() {
        if (!initialized || !ThemeService.initialized || pendingCacheId !== "" || cacheAdapter === null
                || cacheAdapter.availability !== "available") return false;
        cacheStatus = "pending";
        pendingCacheId = `cache-${nextOperationId++}`;
        if (!cacheAdapter.sync(wallpaperDirectory, cacheDirectory, pendingCacheId)) {
            if (cacheAdapter.running) return true;
            lastError = "wallpaper cache sync could not start";
            pendingCacheId = "";
            cacheStatus = "failed";
            return false;
        }
        return true;
    }

    function currentVariant() {
        return ThemeService.theme.variant === "light" ? "light" : "dark";
    }

    function pathFromUrl(url) {
        const text = url.toString();
        return decodeURIComponent(text.startsWith("file://") ? text.slice(7) : text);
    }

    function urlForPath(path) {
        return `file://${path.split("/").map(part => encodeURIComponent(part)).join("/")}`;
    }

    function loadManifest() {
        if (!cacheManifest.loaded) return;
        thumbnailModel.clear();
        for (const line of cacheManifest.text().split("\n")) {
            const fields = line.split("\t");
            if (fields.length !== 2 || !/^[^/]+\.jpg$/.test(fields[0])) continue;
            if (!validPath(fields[1])) continue;
            thumbnailModel.append({
                thumbnailUrl: root.urlForPath(`${root.cacheDirectory}/${fields[0]}`),
                sourcePath: fields[1],
                fileName: fields[1].split("/").pop()
            });
        }
        cacheUpdated();
    }

    function handleWallpaperResult(result) {
        if (result.operationId !== pendingOperationId) return;
        if (!result.success) {
            lastError = result.error || "wallpaper helper failed";
            operation = "failed";
            pendingPath = "";
            pendingOperationId = "";
            return;
        }
        stateFile.setText(JSON.stringify({ schemaVersion: 1, selectedPath: pendingPath }, null, 2) + "\n");
    }

    function handleGenerationResult(result) {
        if (result.operationId !== pendingGenerationId) return;
        if (!result.success || result.theme === null) {
            failGeneration(result.error || "Matugen output was rejected");
            return;
        }
        pendingGenerationStagePath = PathsService.dataPath(`.wallpaper-staging/${pendingGenerationId}/Wallpaper.json`);
        pendingExternalColors = result.colors !== null && result.colors !== undefined ? JSON.stringify(result.colors) : "";
        const stagedContent = JSON.stringify(result.theme, null, 2) + "\n";
        publishedTheme.reload();
        if (publishedTheme.loaded && publishedTheme.text() === stagedContent) {
            root.completeGeneration();
            return;
        }
        stagedTheme.path = pendingGenerationStagePath;
        stagedTheme.stagedThemePending = true;
        stagedTheme.setText(stagedContent);
    }

    function failGeneration(error) {
        generationStatus = "failed";
        lastError = error;
        pendingGenerationPath = "";
        pendingGenerationId = "";
        const queuedPath = generationQueuedPath;
        generationQueuedPath = "";
        if (queuedPath && requestGeneration(queuedPath)) return;
        if (ThemeService.activeThemeId === "wallpaper"
                && externalThemeStatus !== "pending")
            ThemeService.applyExternalTheme("wallpaper", `wallpaper-fallback-${nextOperationId++}`, true);
    }

    function completeGeneration() {
        ThemeCatalogService.refreshGeneratedTheme();
        generationStatus = "succeeded";
        root.startExternalThemeGeneration();
        pendingGenerationPath = "";
        pendingGenerationId = "";
        lastError = "";
        const queuedPath = generationQueuedPath;
        generationQueuedPath = "";
        if (queuedPath) requestGeneration(queuedPath);
    }

    function handlePromotionResult(result) {
        if (result.operationId !== pendingGenerationId) return;
        if (!result.success) {
            failGeneration(result.error || "Wallpaper theme promotion failed");
            return;
        }
        root.completeGeneration();
    }

    function externalBases() {
        const home = Quickshell.env("HOME");
        return {
            home,
            config: `${home}/.config`,
            zshConfig: Quickshell.env("ZSH_CONFIG_HOME") || `${home}/.config/zsh`,
            cache: Quickshell.env("XDG_CACHE_HOME") || `${home}/.cache`
        };
    }

    function startExternalThemeGeneration() {
        externalThemeStatus = "idle";
        if (pendingExternalColors === "") {
            externalThemeStatus = "failed";
            lastError = "wallpaper generation did not provide a palette";
            return;
        }
        if (externalThemeAdapter === null || externalThemeAdapter.availability !== "available") {
            externalThemeStatus = "unavailable";
            return;
        }
        const palette = JSON.parse(pendingExternalColors);
        const generated = ExternalWallpaperTheme.generateWallpaperExternalTargets(palette, externalBases(), currentVariant());
        if (!generated.ok) {
            externalThemeStatus = "failed";
            lastError = generated.errors.join("; ");
            DiagnosticsService.report("EXTERNAL_WALLPAPER_THEME_REJECTED", "external-theme", "External wallpaper theme generation was rejected", lastError, true, pendingGenerationId);
            return;
        }
        const invalid = generated.targets
            .map(target => ExternalWallpaperTheme.validateExternalTargetContent(target))
            .filter(error => error !== null);
        if (invalid.length > 0) {
            externalThemeStatus = "failed";
            lastError = invalid.join("; ");
            DiagnosticsService.report("EXTERNAL_WALLPAPER_THEME_INVALID", "external-theme", "External wallpaper theme content is invalid", lastError, true, pendingGenerationId);
            return;
        }
        pendingExternalId = `external-theme-${nextOperationId++}`;
        pendingExternalSpecPath = PathsService.dataPath(`.wallpaper-staging/${pendingGenerationId}/external.json`);
        externalThemeStatus = "pending";
        externalSpecFile.path = pendingExternalSpecPath;
        externalSpecFile.setText(JSON.stringify({ schemaVersion: 1, operationId: pendingExternalId, variant: currentVariant(), targets: generated.targets }, null, 2) + "\n");
    }

    function handleExternalThemeResult(result) {
        if (result.operationId !== pendingExternalId) return;
        externalThemeResults = result.results;
        externalThemeFailedTargets = result.failedTargets;
        pendingExternalSpecPath = "";
        pendingExternalId = "";
        if (!result.contractValid || result.status === "failed") {
            externalThemeStatus = "failed";
            lastError = result.error || "external wallpaper theme promotion failed";
            DiagnosticsService.report("EXTERNAL_WALLPAPER_THEME_FAILED", "external-theme", "External wallpaper theme promotion failed", lastError, true, result.operationId);
            return;
        }
        if (result.status === "partial") {
            externalThemeStatus = "partial";
            lastError = `external wallpaper theme partial: ${result.failedTargets.join(", ")}`;
            DiagnosticsService.report("EXTERNAL_WALLPAPER_THEME_PARTIAL", "external-theme", "External wallpaper theme promotion was partial", lastError, true, result.operationId);
            return;
        }
        externalThemeStatus = "succeeded";
        lastError = "";
        if (ThemeService.activeThemeId === "wallpaper")
            ThemeService.applyExternalTheme("wallpaper", `wallpaper-external-${nextOperationId++}`, true);
    }

    function loadState() {
        if (!stateFile.loaded) return;
        let parsed;
        try {
            parsed = Wallpaper.validateWallpaperState(JSON.parse(stateFile.text()));
        } catch (error) {
            parsed = { ok: false, errors: [`invalid JSON: ${error.message}`], value: null };
        }
        if (!parsed.ok || !validPath(parsed.value.selectedPath)) {
            lastError = "invalid wallpaper state ignored";
            DiagnosticsService.report("WALLPAPER_STATE_REJECTED", "wallpaper-state", "Invalid wallpaper state ignored", parsed.errors.join("; ") || "path is outside the configured wallpaper root", true, null);
        } else {
            selectedPath = parsed.value.selectedPath;
            appliedPath = parsed.value.selectedPath;
        }
        stateReady = true;
        freshness = "current";
        initialized = true;
        root.syncCache();
        if (ThemeService.activeThemeId === "wallpaper")
            root.requestGeneration(selectedPath);
    }

    FileView {
        id: stateFile
        path: PathsService.wallpaperState
        blockLoading: true
        atomicWrites: true
        printErrors: false
        onLoaded: root.loadState()
        onLoadFailed: {
            root.stateReady = true;
            root.freshness = "current";
            root.initialized = true;
            root.syncCache();
        }
        onSaved: {
            root.selectedPath = root.pendingPath;
            root.appliedPath = root.pendingPath;
            root.requestedPath = root.pendingPath;
            root.pendingPath = "";
            root.pendingOperationId = "";
            root.operation = "succeeded";
            root.lastError = "";
            root.requestGeneration(root.selectedPath);
        }
        onSaveFailed: error => {
            root.lastError = `wallpaper state write failed: ${error}`;
            root.pendingPath = "";
            root.pendingOperationId = "";
            root.operation = "failed";
        }
    }

    FileView {
        id: stagedTheme
        blockLoading: true
        atomicWrites: true
        printErrors: false
        property bool stagedThemePending: false
        onSaved: {
            if (!stagedThemePending) return;
            stagedThemePending = false;
            if (root.promotionAdapter === null
                    || root.promotionAdapter.availability !== "available"
                    || !root.promotionAdapter.promote(root.pendingGenerationStagePath,
                        PathsService.generatedThemePath, root.pendingGenerationId))
                root.failGeneration("Wallpaper theme promotion could not start");
        }
        onSaveFailed: error => {
            if (stagedThemePending) stagedThemePending = false;
            root.failGeneration(`staged Wallpaper theme write failed: ${error}`);
        }
    }

    FileView {
        id: publishedTheme
        path: PathsService.generatedThemePath
        blockLoading: true
        blockAllReads: true
        printErrors: false
    }

    FileView {
        id: externalSpecFile
        blockLoading: true
        atomicWrites: true
        printErrors: false
        onSaved: {
            if (root.externalThemeStatus !== "pending") return;
            if (root.externalThemeAdapter === null
                    || root.externalThemeAdapter.availability !== "available"
                    || !root.externalThemeAdapter.apply(root.pendingExternalSpecPath, root.pendingExternalId)) {
                root.externalThemeStatus = "failed";
                root.lastError = "external wallpaper theme promotion could not start";
            }
        }
        onSaveFailed: error => {
            if (root.externalThemeStatus === "pending") {
                root.externalThemeStatus = "failed";
                root.lastError = `external wallpaper theme spec write failed: ${error}`;
            }
        }
    }

    FolderListModel {
        id: wallpaperFiles
        folder: `file://${root.wallpaperDirectory}/`
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif"]
        showDirs: false
        showFiles: true
        showHidden: false
        showOnlyReadable: true
        sortField: FolderListModel.Name
        sortCaseSensitive: true
    }

    ListModel {
        id: thumbnailModel
    }

    FileView {
        id: cacheManifest
        path: root.cacheManifestPath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.loadManifest()
        onFileChanged: reload()
        onLoadFailed: thumbnailModel.clear()
    }

    Connections {
        target: root.wallpaperAdapter
        ignoreUnknownSignals: true
        function onFinished(result) { root.handleWallpaperResult(result); }
        function onAvailabilityChanged() { root.refreshAvailability(); }
    }

    Connections {
        target: root.matugenAdapter
        ignoreUnknownSignals: true
        function onFinished(result) { root.handleGenerationResult(result); }
    }

    Connections {
        target: root.promotionAdapter
        ignoreUnknownSignals: true
        function onFinished(result) { root.handlePromotionResult(result); }
    }

    Connections {
        target: root.cacheAdapter
        ignoreUnknownSignals: true
        function onFinished(result) {
            if (result.operationId !== root.pendingCacheId) return;
            root.cacheStatus = result.success ? "succeeded" : "failed";
            root.lastError = result.success ? "" : result.error;
            root.pendingCacheId = "";
            if (result.success) cacheManifest.reload();
        }
        function onAvailabilityChanged() { root.syncCache(); }
    }

    Connections {
        target: root.externalThemeAdapter
        ignoreUnknownSignals: true
        function onFinished(result) { root.handleExternalThemeResult(result); }
    }

    Connections {
        target: ThemeService
        function onActiveThemeIdChanged() {
            root.syncCache();
            if (ThemeService.activeThemeId !== "wallpaper") return;
            if (root.selectedPath) {
                // Regeneration refreshes the generated external slots. If it
                // cannot start, still select the last promoted wallpaper slots.
                if (!root.requestGeneration(root.selectedPath)
                        && root.generationStatus !== "pending"
                        && root.externalThemeStatus !== "pending")
                    ThemeService.applyExternalTheme("wallpaper", `wallpaper-restored-${root.nextOperationId++}`, true);
            } else if (root.generationStatus !== "pending" && root.externalThemeStatus !== "pending") {
                ThemeService.applyExternalTheme("wallpaper", `wallpaper-restored-${root.nextOperationId++}`, true);
            }
        }
        function onInitializedChanged() { root.syncCache(); }
    }

    onWallpaperAdapterChanged: refreshAvailability()
    onCacheAdapterChanged: syncCache()
    Component.onCompleted: refreshAvailability()
}
