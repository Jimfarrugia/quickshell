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
        if (pendingLaunch !== null || launcherProcess.running) return false;
        lastFailure = "";
        try {
            const applicationCommand = Array.from(entry.command || []).map(argument => String(argument));
            const terminal = String(Quickshell.env("TERMINAL") || "kitty").trim();
            const command = entry.runInTerminal
                ? [terminal, "--", ...applicationCommand]
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
