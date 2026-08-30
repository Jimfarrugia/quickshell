pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Notifications.mjs" as Notifications
import "../utils/Validation.mjs" as Validation

Singleton {
    id: root

    signal historyAboutToChange()

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
    property bool popupsBlocked: false
    property var popupNotifications: []
    property var popupExpirations: ({})
    property var history: []
    property var records: []
    readonly property int popupExpiryMs: 5000

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
        const previousData = index >= 0 ? records[index].data : null;
        data.receivedAt = previousData && Number.isFinite(previousData.receivedAt)
            ? previousData.receivedAt : Date.now();
        const record = { data: data, native: nativeNotification };
        if (index >= 0) {
            records = replaceAt(records, index, record);
            root.historyAboutToChange();
            updateHistory(record);
            updatePopup(record);
            if (root.popupIndex(data.id) >= 0 && data.urgency !== "critical")
                root.schedulePopupExpiry(data.id);
            else
                root.removePopupExpiry(data.id);
            return true;
        }

        records = records.concat([record]);
        if (Notifications.shouldKeepHistory(data, ConfigService.config.notifications.historyEnabled)) {
            root.historyAboutToChange();
            history = [{ data: data, native: nativeNotification }].concat(history)
                .slice(0, ConfigService.config.notifications.historyLimit);
        }
        if (!root.popupsBlocked && !data.lastGeneration && ConfigService.config.notifications.popupEnabled
                && Notifications.shouldShowPopup(data, dnd)) {
            popupNotifications = popupNotifications.concat([record]);
            if (data.urgency !== "critical") root.schedulePopupExpiry(data.id);
        }
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

    function hidePopup(id) {
        const index = popupIndex(id);
        if (index >= 0) popupNotifications = popupNotifications.filter((_, popupIndex) => popupIndex !== index);
        root.removePopupExpiry(id);
    }

    function schedulePopupExpiry(id) {
        const next = Object.assign({}, popupExpirations);
        next[id] = Date.now() + root.popupExpiryMs;
        popupExpirations = next;
        root.scheduleNextPopupExpiry();
    }

    function removePopupExpiry(id) {
        if (popupExpirations[id] === undefined) return;
        const next = Object.assign({}, popupExpirations);
        delete next[id];
        popupExpirations = next;
        root.scheduleNextPopupExpiry();
    }

    function scheduleNextPopupExpiry() {
        const ids = Object.keys(popupExpirations);
        if (ids.length === 0) {
            popupExpiryTimer.stop();
            return;
        }
        let next = popupExpirations[ids[0]];
        for (let index = 1; index < ids.length; index++)
            next = Math.min(next, popupExpirations[ids[index]]);
        popupExpiryTimer.interval = Math.max(1, next - Date.now());
        popupExpiryTimer.restart();
    }

    function expireDuePopups() {
        const now = Date.now();
        const next = {};
        for (const id of Object.keys(popupExpirations)) {
            if (popupExpirations[id] > now) next[id] = popupExpirations[id];
            else {
                const index = root.recordIndex(Number(id));
                if (index >= 0 && records[index].data.actions.length > 0)
                    root.hidePopup(Number(id));
                else
                    root.expire(Number(id));
            }
        }
        popupExpirations = next;
        root.scheduleNextPopupExpiry();
    }

    function closeNotification(nativeNotification) {
        if (!nativeNotification) return;
        const id = Number(nativeNotification.id);
        const popup = popupIndex(id);
        if (popup >= 0) popupNotifications = popupNotifications.filter((_, index) => index !== popup);
        root.removePopupExpiry(id);
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
        for (let actionIndex = 0; actionIndex < actions.length; actionIndex++) {
            const action = actions[actionIndex];
            if (action.identifier === identifier) {
                action.invoke();
                return true;
            }
        }
        return false;
    }

    function removeFromHistory(id) {
        const index = historyIndex(Number(id));
        if (index < 0) return false;
        root.historyAboutToChange();
        history = history.filter((_, entryIndex) => entryIndex !== index);
        return true;
    }

    function clearHistory() { history = []; }

    function dismissPopups() {
        const ids = popupNotifications.map(record => record.data.id);
        for (const id of ids) root.hidePopup(id);
        popupExpirations = {};
        popupExpiryTimer.stop();
    }

    function setPopupsBlocked(blocked) {
        if (typeof blocked !== "boolean") return false;
        popupsBlocked = blocked;
        if (blocked) root.dismissPopups();
        return true;
    }

    function dismissAll() {
        const current = records.slice();
        for (const record of current) {
            if (record.native && typeof record.native.dismiss === "function") record.native.dismiss();
        }
        root.dismissPopups();
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

    Timer {
        id: popupExpiryTimer
        repeat: false
        onTriggered: root.expireDuePopups()
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
