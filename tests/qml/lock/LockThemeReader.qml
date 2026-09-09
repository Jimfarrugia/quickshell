import QtQuick
import QtQml.Models
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../utils/Validation.mjs" as Validation

QtObject {
    id: root

    property string configPath: Quickshell.shellPath("config/qe.json")
    property string activeThemeStatePath: Quickshell.statePath("active-theme.json")
    property string themeDirectory: Quickshell.shellPath("themes")
    property string generatedThemePath: {
        const dataHome = Quickshell.env("XDG_DATA_HOME")
            || `${Quickshell.env("HOME")}/.local/share`;
        return `${dataHome}/qe/wallpaper/Wallpaper.json`;
    }
    property int loadTimeoutMs: 1500
    property int detachmentDelayMs: 25
    property int maxInputCharacters: 262144
    property bool ready: false
    property bool usingFallback: true
    property var errors: []
    property var appearance: Validation.defaultConfig.appearance
    property var theme: emergencyTheme
    readonly property bool watchersActive: !frozen || themeFiles.count > 0
    property bool frozen: false
    property bool deactivating: false
    property var pendingTheme: emergencyTheme
    property var pendingAppearance: Validation.defaultConfig.appearance
    property bool pendingUsingFallback: true
    property var pendingErrors: []
    property bool configSettled: false
    property bool stateSettled: false
    property var configResult: null
    property var stateResult: null

    readonly property var emergencyTheme: ({
        schemaVersion: 1,
        id: "lock_emergency",
        name: "Lock Emergency",
        variant: "dark",
        palette: { background: "#000000", foreground: "#ffffff" },
        tokens: {
            background: "#000000", on_background: "#ffffff",
            surface: "#000000", on_surface: "#ffffff", on_surface_subdued: "#b0b0b0", on_surface_indicator: "#d0d0d0",
            surface_variant: "#000000", on_surface_variant: "#ffffff",
            surface_panel: "#000000", surface_sidebar: "#000000",
            surface_low: "#000000", on_surface_panel: "#ffffff",
            surface_tooltip: "#000000", on_surface_tooltip: "#ffffff",
            surface_hover: "#181818", surface_pressed: "#242424",
            primary: "#ffffff", on_primary: "#000000",
            primary_container: "#242424", on_primary_container: "#ffffff",
            secondary: "#ffffff", on_secondary: "#000000",
            outline: "#808080", outline_variant: "#404040",
            focus_ring: "#ffffff", on_surface_disabled: "#808080",
            on_surface_placeholder: "#b0b0b0", link: "#ffffff",
            highlight: "#ffffff", on_highlight: "#000000",
            success: "#ffffff", warning: "#ffffff", error: "#ff6060",
            shadow: "#ff000000", scrim: "#ff000000", charging: "#ffffff"
        }
    })

    function parse(view, boundary, validator) {
        if (!view.loaded) return { ok: false, value: null, errors: [`${boundary}: unavailable`] };
        const text = view.text();
        if (text.length > maxInputCharacters)
            return { ok: false, value: null, errors: [`${boundary}: input is too large`] };
        const parsed = Validation.parseJson(text, boundary);
        return parsed.ok ? validator(parsed.value) : parsed;
    }

    function allThemesSettled() {
        if (themeFolder.status !== FolderListModel.Ready || themeFiles.count !== themeFolder.count
                || !generatedTheme.settled)
            return false;
        for (let index = 0; index < themeFiles.count; index++) {
            const file = themeFiles.objectAt(index);
            if (file === null || !file.settled) return false;
        }
        return true;
    }

    function finish() {
        if (ready || deactivating || !configSettled || !stateSettled || !allThemesSettled()) return;
        let collectedErrors = [];
        if (configResult !== null && configResult.ok && configResult.errors.length === 0) {
            pendingAppearance = configResult.value.appearance;
        } else if (configResult !== null) {
            collectedErrors = collectedErrors.concat(configResult.errors);
        }

        let activeId = "";
        if (stateResult !== null && stateResult.ok) activeId = stateResult.value.activeThemeId;
        else if (stateResult !== null) collectedErrors = collectedErrors.concat(stateResult.errors);

        let matches = [];
        for (let index = 0; index < themeFiles.count; index++) {
            const file = themeFiles.objectAt(index);
            collectedErrors = collectedErrors.concat(file.errors);
            if (file.candidate !== null && file.candidate.id === activeId)
                matches.push(file.candidate);
        }
        collectedErrors = collectedErrors.concat(generatedTheme.errors);
        if (generatedTheme.candidate !== null && generatedTheme.candidate.id === activeId)
            matches.push(generatedTheme.candidate);

        if (activeId.length > 0 && matches.length === 1) {
            pendingTheme = matches[0];
            pendingUsingFallback = false;
        } else if (matches.length > 1) {
            collectedErrors.push(`active theme '${activeId}' is duplicated`);
        } else if (activeId.length > 0) {
            collectedErrors.push(`active theme '${activeId}' is unavailable`);
        }
        pendingErrors = collectedErrors;
        deactivating = true;
        frozen = true;
        loadTimeout.stop();
        publishIfDetached();
    }

    function finishWithFallback(reason) {
        if (ready) return;
        pendingErrors = errors.concat([reason]);
        deactivating = true;
        frozen = true;
        publishIfDetached();
    }

    function publishIfDetached() {
        if (!deactivating || themeFiles.count !== 0) return;
        detachmentTimer.restart();
    }

    function publishDetached() {
        if (!deactivating || themeFiles.count !== 0) return;
        theme = pendingTheme;
        appearance = pendingAppearance;
        usingFallback = pendingUsingFallback;
        errors = pendingErrors;
        ready = true;
    }

    property FileView configFile: FileView {
        path: root.configPath
        blockLoading: true
        watchChanges: false
        printErrors: false
        onLoaded: {
            root.configResult = root.parse(this, "lock config", Validation.validateConfig);
            root.configSettled = true;
            root.finish();
        }
        onLoadFailed: {
            root.configResult = { ok: false, value: null, errors: ["lock config: unavailable"] };
            root.configSettled = true;
            root.finish();
        }
    }

    property FileView activeStateFile: FileView {
        path: root.activeThemeStatePath
        blockLoading: true
        watchChanges: false
        printErrors: false
        onLoaded: {
            root.stateResult = root.parse(this, "lock active theme state", Validation.validateThemeState);
            root.stateSettled = true;
            root.finish();
        }
        onLoadFailed: {
            root.stateResult = { ok: false, value: null, errors: ["lock active theme state: unavailable"] };
            root.stateSettled = true;
            root.finish();
        }
    }

    property FolderListModel themeFolder: FolderListModel {
        folder: root.frozen ? "file:///qe-lock-reader-disabled-does-not-exist" : `file://${root.themeDirectory}/`
        nameFilters: ["*.json"]
        showDirs: false
        showFiles: true
        showHidden: false
        showOnlyReadable: true
        sortField: FolderListModel.Name
        onStatusChanged: {
            root.finish();
            root.publishIfDetached();
        }
        onCountChanged: {
            root.finish();
            root.publishIfDetached();
        }
    }

    property Instantiator themeFiles: Instantiator {
        model: root.frozen ? 0 : root.themeFolder
        delegate: FileView {
            required property string fileName
            property var candidate: null
            property var errors: []
            property bool settled: false
            readonly property bool ignored: fileName === "schema.json"
            path: `${root.themeDirectory}/${fileName}`
            blockLoading: true
            watchChanges: false
            printErrors: false
            onLoaded: {
                const result = ignored
                    ? { ok: false, value: null, errors: [] }
                    : root.parse(this, `lock theme ${fileName}`, Validation.validateTheme);
                candidate = result.ok ? result.value : null;
                errors = result.errors;
                settled = true;
                root.finish();
            }
            onLoadFailed: {
                errors = ignored ? [] : [`lock theme ${fileName}: unavailable`];
                settled = true;
                root.finish();
            }
        }
        onObjectAdded: root.finish()
        onObjectRemoved: {
            root.finish();
            root.publishIfDetached();
        }
    }

    property FileView generatedTheme: FileView {
        property var candidate: null
        property var errors: []
        property bool settled: false
        path: root.generatedThemePath
        blockLoading: true
        watchChanges: false
        printErrors: false
        onLoaded: {
            const result = root.parse(this, "lock generated theme", Validation.validateTheme);
            candidate = result.ok ? result.value : null;
            errors = result.errors;
            settled = true;
            root.finish();
        }
        onLoadFailed: {
            settled = true;
            root.finish();
        }
    }

    property Timer loadTimeout: Timer {
        interval: root.loadTimeoutMs
        running: true
        repeat: false
        onTriggered: root.finishWithFallback("lock-safe input loading timed out")
    }

    property Timer detachmentTimer: Timer {
        interval: root.detachmentDelayMs
        repeat: false
        onTriggered: root.publishDetached()
    }
}
