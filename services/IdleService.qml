pragma Singleton

import Quickshell
import "../integrations" as Integrations

Singleton {
    id: root

    property var integration: nativeIntegration
    property bool requested: false
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
        return true;
    }

    function toggle() {
        return setRequested(!requested);
    }

    function updateIntegration() {
        integration.ownerWindow = ownerWindow;
        integration.requested = requested && ownerWindow !== null;
    }

    onIntegrationChanged: updateIntegration()
    onConfiguredChanged: if (!configured && requested) setRequested(false)

    Integrations.IdleInhibitorIntegration { id: nativeIntegration }
}
