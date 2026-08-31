import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Scope {
    id: root

    property bool active: true
    readonly property string helperPath: Quickshell.shellPath("scripts/qe-notification-owner.sh")
    readonly property string owner: ownerState
    property string ownerState: "unknown"
    property string ownerUniqueName: ""
    property int ownerPid: 0
    property string availability: !active ? "unavailable"
        : (ownerState === "qe" ? "available" : (ownerState === "unknown" ? "unknown" : "unavailable"))
    property string freshness: lastUpdated === null ? "unknown" : "current"
    property var lastUpdated: null
    property var lastError: null
    readonly property string operation: "idle"

    signal notificationReceived(var notification)
    signal notificationUpdated(var notification)
    signal notificationClosed(var notification, var reason)

    function publishOwner(record) {
        if (!record || record.schemaVersion !== 1
                || ["none", "qe", "dunst", "other"].indexOf(record.owner) === -1
                || typeof record.uniqueName !== "string"
                || !Number.isInteger(record.pid) || record.pid < 0) {
            ownerState = "unknown";
            lastError = "notification owner watcher returned malformed output";
            return;
        }
        ownerState = record.owner;
        ownerUniqueName = record.uniqueName;
        ownerPid = record.pid;
        lastUpdated = new Date();
        lastError = ownerState === "dunst"
            ? "Dunst owns org.freedesktop.Notifications"
            : ownerState === "other" ? "Another notification service owns the DBus name" : null;
    }

    function consumeOwnerLine(line) {
        if (typeof line !== "string" || line.length === 0 || line.length > 1024) return;
        try {
            publishOwner(JSON.parse(line));
        } catch (error) {
            ownerState = "unknown";
            lastError = `notification owner output is malformed: ${error.message}`;
        }
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: false
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: false
        bodyImagesSupported: true
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true
        inlineReplySupported: false
        onNotification: notification => {
            notification.tracked = true;
            root.notificationReceived(notification);
        }
    }

    Instantiator {
        model: server.trackedNotifications
        delegate: Connections {
            required property var modelData
            target: modelData
            function onClosed(reason) { root.notificationClosed(modelData, reason); }
            function onSummaryChanged() { root.notificationUpdated(modelData); }
            function onBodyChanged() { root.notificationUpdated(modelData); }
            function onActionsChanged() { root.notificationUpdated(modelData); }
            function onImageChanged() { root.notificationUpdated(modelData); }
            function onUrgencyChanged() { root.notificationUpdated(modelData); }
            function onExpireTimeoutChanged() { root.notificationUpdated(modelData); }
        }
    }

    Process {
        id: ownerWatcher
        command: ["setpriv", "--pdeathsig", "TERM", root.helperPath,
            "--qe-pid", String(Quickshell.processId)]
        running: root.active
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.consumeOwnerLine(data)
        }
        onExited: {
            if (root.active) {
                root.ownerState = "unknown";
                root.lastError = "notification owner watcher exited";
            }
        }
    }
}
