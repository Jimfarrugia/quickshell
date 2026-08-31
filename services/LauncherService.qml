pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Launcher.mjs" as Launcher

Singleton {
    id: root
    property string query: ""
    property int selectedIndex: 0
    property var usage: ({})
    property var results: []
    property string lastFailure: ""
    property bool loaded: false
    property string lastPersistenceError: ""

    function refresh() {
        const selectedId = results[selectedIndex]?.id || "";
        results = Launcher.rank(DesktopEntries.applications.values, query, usage);
        const retained = results.findIndex(entry => entry.id === selectedId);
        selectedIndex = retained >= 0 ? retained : 0;
    }
    function open() { query = ""; selectedIndex = 0; refresh(); SurfaceService.openLauncher(); }
    function toggle() { SurfaceService.launcherVisible ? close() : open(); }
    function close() { SurfaceService.closeLauncher(); }
    function setQuery(value) { query = value; refresh(); }
    function move(delta) {
        if (!results.length) return;
        selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + delta));
    }
    function launch(index) {
        const entry = results[index];
        if (!entry || !Launcher.isEligible(entry)) return false;
        lastFailure = "";
        try {
            const command = Array.from(entry.command || []).map(argument => String(argument));
            launcherProcess.command = command;
            launcherProcess.workingDirectory = String(entry.workingDirectory || "");
            launcherProcess.startDetached();
            const current = usage[entry.id]?.launchCount || 0;
            const nextUsage = Object.assign({}, usage, { [entry.id]: { launchCount: current + 1 } });
            usage = Launcher.boundedUsage(nextUsage, DesktopEntries.applications.values.map(item => item.id));
            lastPersistenceError = "";
            stateFile.setText(JSON.stringify({ schemaVersion: 1, entries: usage }, null, 2) + "\n");
            close();
            return true;
        } catch (error) {
            lastFailure = `Could not launch ${entry.name}: ${String(error)}`.slice(0, 256);
            DiagnosticsService.report("LAUNCH_FAILED", "launcher", "Application launch failed", lastFailure, true, null);
            return false;
        }
    }
    function loadUsage() {
        if (!stateFile.loaded) { loaded = true; return; }
        try {
            const parsed = Launcher.validateUsage(JSON.parse(stateFile.text()));
            if (parsed === null) throw new Error("invalid schema");
            usage = parsed;
        }
        catch (error) {
            usage = {};
            DiagnosticsService.report("LAUNCHER_USAGE_REJECTED", "launcher", "Usage state ignored", "Malformed or incompatible launcher-usage.json", false, null);
        }
        loaded = true;
        refresh();
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.refresh(); }
    }
    FileView {
        id: stateFile
        path: PathsService.launcherUsageState
        blockLoading: true
        atomicWrites: true
        printErrors: false
        onLoaded: root.loadUsage()
        onLoadFailed: root.loadUsage()
        onSaveFailed: error => {
            root.lastPersistenceError = "Launcher usage could not be saved";
            DiagnosticsService.report("LAUNCHER_USAGE_SAVE_FAILED", "launcher", "Usage count was not persisted", root.lastPersistenceError, true, null);
        }
    }
    Process { id: launcherProcess }
    Component.onCompleted: { root.loadUsage(); root.refresh(); }
}
