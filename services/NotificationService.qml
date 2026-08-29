pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Notifications.mjs" as Notifications
import "../utils/Validation.mjs" as Validation

Singleton {
    id: root

    property var integration: null
    readonly property string availability: integration === null ? "unavailable" : integration.availability
    readonly property string freshness: integration === null ? "unknown" : integration.freshness
    readonly property var lastUpdated: integration === null ? null : integration.lastUpdated
    readonly property var lastError: integration === null ? null : integration.lastError
    readonly property string operation: "idle"
    readonly property bool ready: integration !== null && integration.owner === "qe"
    readonly property string owner: integration === null ? "none" : integration.owner
    property bool dnd: false
    property bool stateReady: false
    property var popupNotifications: []
    property var history: []
    property var records: []

    function limits() {
        const config = ConfigService.config.notifications;
        return {
            maxSummaryBytes: config.maxSummaryBytes,
            maxBodyBytes: config.maxBodyBytes,
            maxActions: config.maxActions
        };
    }

    function recordIndex(id) {
        return records.findIndex(record => record.data.id === id);
    }

    function historyIndex(id) {
        return history.findIndex(record => record.data.id === id);
    }

    function popupIndex(id) {
        return popupNotifications.findIndex(record => record.data.id === id);
    }

    function replaceAt(list, index, value) {
        const next = list.slice();
        if (index >= 0) next[index] = value;
        return next;
    }

    function accept(nativeNotification) {
        if (!nativeNotification || root.integration === null) return false;
        const data = Notifications.normalizeNotification(nativeNotification, root.limits());
        if (data.id <= 0) return false;
        const index = root.recordIndex(data.id);
        const record = { data: data, native: nativeNotification };
        if (index >= 0) {
            records = replaceAt(records, index, record);
            updateHistory(record);
            updatePopup(record);
            return true;
        }

        records = records.concat([record]);
        if (Notifications.shouldKeepHistory(data, ConfigService.config.notifications.historyEnabled)) {
            history = [{ data: data, native: nativeNotification }].concat(history)
                .slice(0, ConfigService.config.notifications.historyLimit);
        }
        if (!data.lastGeneration && ConfigService.config.notifications.popupEnabled
                && Notifications.shouldShowPopup(data, dnd))
            popupNotifications = popupNotifications.concat([record]);
        return true;
    }

    function updateHistory(record) {
        const index = historyIndex(record.data.id);
        if (index >= 0) history = replaceAt(history, index, record);
    }

    function updatePopup(record) {
        const index = popupIndex(record.data.id);
        if (index >= 0) popupNotifications = replaceAt(popupNotifications, index, record);
    }

    function closeNotification(nativeNotification) {
        if (!nativeNotification) return;
        const id = Number(nativeNotification.id);
        const popup = popupIndex(id);
        if (popup >= 0) popupNotifications = popupNotifications.filter((_, index) => index !== popup);
    }

    function dismiss(id) {
        const index = recordIndex(id);
        if (index < 0) return false;
        records[index].native.dismiss();
        return true;
    }

    function expire(id) {
        const index = recordIndex(id);
        if (index < 0) return false;
        records[index].native.expire();
        return true;
    }

    function invokeAction(id, identifier) {
        const index = recordIndex(id);
        if (index < 0 || typeof identifier !== "string") return false;
        const actions = records[index].native.actions || [];
        for (const action of actions) {
            if (action.identifier === identifier) {
                action.invoke();
                return true;
            }
        }
        return false;
    }

    function clearHistory() { history = []; }

    function dismissAll() {
        const current = records.slice();
        for (const record of current) {
            if (record.native && typeof record.native.dismiss === "function") record.native.dismiss();
        }
        popupNotifications = [];
    }

    function setDnd(value) {
        if (!stateReady || typeof value !== "boolean") return false;
        dnd = value;
        stateFile.setText(JSON.stringify({ schemaVersion: 1, dnd: dnd }, null, 2) + "\n");
        return true;
    }

    function loadState() {
        if (!stateFile.loaded) return;
        const parsed = Validation.parseJson(stateFile.text(), "notification state");
        if (!parsed.ok) {
            stateReady = true;
            DiagnosticsService.report("NOTIFICATION_STATE_REJECTED", "notification-state", "Invalid notification state ignored", parsed.errors.join("; "), true, null);
            return;
        }
        const state = Validation.validateNotificationState(parsed.value);
        if (!state.ok) {
            stateReady = true;
            DiagnosticsService.report("NOTIFICATION_STATE_REJECTED", "notification-state", "Invalid notification state ignored", state.errors.join("; "), true, null);
            return;
        }
        dnd = state.value.dnd;
        stateReady = true;
    }

    Connections {
        target: root.integration
        ignoreUnknownSignals: true
        function onNotificationReceived(notification) { root.accept(notification); }
        function onNotificationUpdated(notification) { root.accept(notification); }
        function onNotificationClosed(notification) { root.closeNotification(notification); }
    }

    FileView {
        id: stateFile
        path: PathsService.notificationState
        blockLoading: true
        atomicWrites: true
        printErrors: false
        onLoaded: root.loadState()
        onLoadFailed: root.stateReady = true
    }
}
