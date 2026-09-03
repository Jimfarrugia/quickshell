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
    property var pendingLaunch: null
    property var failedLaunch: null
    property bool selectionExplicit: false

    function refresh(preserveSelection = selectionExplicit) {
        const selectedId = preserveSelection ? results[selectedIndex]?.id || "" : "";
        results = Launcher.rank(Launcher.curatedDashboardActions.concat(
            DesktopEntries.applications.values), query, usage);
        const retained = results.findIndex(entry => entry.id === selectedId);
        selectedIndex = retained >= 0 ? retained : 0;
        if (preserveSelection && retained < 0) selectionExplicit = false;
    }
    function open() {
        query = "";
        selectedIndex = 0;
        selectionExplicit = false;
        lastFailure = "";
        failedLaunch = null;
        refresh(false);
        SurfaceService.openLauncher();
    }
    function toggle() { SurfaceService.launcherVisible ? close() : open(); }
    function close() {
        lastFailure = "";
        failedLaunch = null;
        SurfaceService.closeLauncher();
    }
    function setQuery(value) { query = value; selectionExplicit = false; refresh(false); }
    function select(index) {
        if (index < 0 || index >= results.length) return;
        selectedIndex = index;
        selectionExplicit = true;
    }
    function move(delta) {
        if (!results.length) return;
        selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + delta));
        selectionExplicit = true;
    }
    function launch(index) { return launchEntry(results[index]); }
    function retry() { return launchEntry(failedLaunch); }
    function launchEntry(entry) {
        if (!entry || !Launcher.isEligible(entry)) return false;
        if (entry.actionId) {
            SurfaceService.closeLauncher();
            SurfaceService.toggleDashboard(entry.actionId, SurfaceService.activeScreen(), "right");
            return true;
        }
        if (pendingLaunch !== null || launcherProcess.running) return false;
        lastFailure = "";
        try {
            const applicationCommand = Array.from(entry.command || []).map(argument => String(argument));
            const terminal = String(Quickshell.env("TERMINAL") || "kitty").trim();
            const command = entry.runInTerminal
                ? [terminal, ...applicationCommand]
                : applicationCommand;
            launcherProcess.command = command;
            launcherProcess.workingDirectory = String(entry.workingDirectory || "");
            pendingLaunch = entry;
            const executable = command[0] || "";
            if (executable.startsWith("/")) {
                launchProbe.command = ["/usr/bin/test", "-x", executable];
                launchProbe.running = true;
            } else {
                launcherProcess.startDetached();
                commitLaunch();
            }
            return true;
        } catch (error) {
            lastFailure = `Could not launch ${entry.name}: ${String(error)}`.slice(0, 256);
            DiagnosticsService.report("LAUNCH_FAILED", "launcher", "Application launch failed", lastFailure, true, null);
            return false;
        }
    }
    function commitLaunch() {
        if (pendingLaunch === null) return;
        const entry = pendingLaunch;
        pendingLaunch = null;
        failedLaunch = null;
        const current = usage[entry.id]?.launchCount || 0;
        const nextUsage = Object.assign({}, usage, { [entry.id]: { launchCount: current + 1 } });
        usage = Launcher.boundedUsage(nextUsage, DesktopEntries.applications.values.map(item => item.id));
        lastPersistenceError = "";
        stateFile.setText(JSON.stringify({ schemaVersion: 1, entries: usage }, null, 2) + "\n");
        close();
    }
    function failLaunch() {
        if (pendingLaunch === null) return;
        const entry = pendingLaunch;
        pendingLaunch = null;
        failedLaunch = entry;
        lastFailure = `Could not launch ${entry.name}: the application could not be started`.slice(0, 256);
        DiagnosticsService.report("LAUNCH_FAILED", "launcher", "Application launch failed", lastFailure, true, null);
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
        refresh(false);
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.refresh(root.selectionExplicit); }
    }
    FileView {
        id: stateFile
        path: PathsService.launcherUsageState
        blockLoading: true
        blockWrites: true
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
    Process {
        id: launchProbe
        onExited: (exitCode, exitStatus) => {
            if (root.pendingLaunch === null) return;
            if (exitCode === 0) {
                launchProbe.running = false;
                launcherProcess.startDetached();
                root.commitLaunch();
            } else {
                root.failLaunch();
            }
        }
    }
    Component.onCompleted: { root.loadUsage(); root.refresh(); }
}
