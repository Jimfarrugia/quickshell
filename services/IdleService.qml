pragma Singleton

import Quickshell
import Quickshell.Io
import "../integrations" as Integrations
import "../utils/Validation.mjs" as Validation

Singleton {
    id: root

    property var integration: nativeIntegration
    property bool requested: false
    property bool stateReady: false
    property var __windows: []
    readonly property bool configured: ConfigService.config.bar.enabled
        && ConfigService.config.bar.idleInhibitorEnabled
    readonly property string availability: integration.availability
    readonly property string freshness: integration.freshness
    readonly property var lastUpdated: integration.lastUpdated
    readonly property var lastError: integration.lastError
    readonly property string operation: integration.operation
    readonly property var ownerWindow: __windows.length > 0 ? __windows[0] : null

    function registerWindow(window) {
        if (!window || __windows.indexOf(window) !== -1) return;
        __windows = __windows.concat([window]);
        updateIntegration();
    }

    function unregisterWindow(window) {
        const remaining = __windows.filter(candidate => candidate !== window);
        if (remaining.length === __windows.length) return;
        __windows = remaining;
        if (__windows.length === 0) requested = false;
        updateIntegration();
    }

    function setRequested(value) {
        if (value && (!configured || availability !== "available")) return false;
        requested = value;
        updateIntegration();
        if (stateReady)
            stateFile.setText(JSON.stringify({ schemaVersion: 1, requested: requested }, null, 2) + "\n");
        return true;
    }

    function toggle() {
        return setRequested(!requested);
    }

    function updateIntegration() {
        integration.ownerWindow = ownerWindow;
        integration.requested = requested && ownerWindow !== null;
    }

    function loadState() {
        if (!stateFile.loaded) return;
        const parsed = Validation.parseJson(stateFile.text(), "idle inhibitor state");
        if (!parsed.ok) {
            stateReady = true;
            DiagnosticsService.report("IDLE_INHIBITOR_STATE_REJECTED", "idle-inhibitor-state", "Invalid idle inhibitor state ignored", parsed.errors.join("; "), true, null);
            return;
        }
        const state = Validation.validateIdleInhibitorState(parsed.value);
        if (!state.ok) {
            stateReady = true;
            DiagnosticsService.report("IDLE_INHIBITOR_STATE_REJECTED", "idle-inhibitor-state", "Invalid idle inhibitor state ignored", state.errors.join("; "), true, null);
            return;
        }
        requested = state.value.requested;
        stateReady = true;
        updateIntegration();
    }

    onIntegrationChanged: updateIntegration()
    onConfiguredChanged: if (!configured && requested) setRequested(false)

    Integrations.IdleInhibitorIntegration { id: nativeIntegration }

    FileView {
        id: stateFile
        path: PathsService.idleInhibitorState
        blockLoading: true
        atomicWrites: true
        printErrors: false
        onLoaded: root.loadState()
        onLoadFailed: root.stateReady = true
    }
}
