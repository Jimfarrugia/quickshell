import QtQuick
import Quickshell
import Quickshell.Io
import "integrations" as Integrations
import "modules/notifications" as Notifications
import "services" as Services

ShellRoot {
    id: root
    property int notificationCount: 0
    property int maxActionCount: 0
    property int lastActionId: 0
    property string lastActionIdentifier: ""
    property string lastImage: ""
    property string lastBody: ""
    property var receivedIds: []
    property bool ownerReported: false

    Integrations.NotificationsIntegration {
        id: integration
        active: true
        onNotificationReceived: notification => {
            root.notificationCount++;
            root.lastImage = notification.image;
            root.lastBody = notification.body;
            root.maxActionCount = Math.max(root.maxActionCount, notification.actions.length);
            if (notification.actions.length > 0) {
                root.lastActionId = Number(notification.id);
                root.lastActionIdentifier = notification.actions[0].identifier;
            }
            root.receivedIds = root.receivedIds.concat([Number(notification.id)]);
            console.log(`NOTIFICATION_RECEIVED_COUNT=${root.notificationCount}`);
        }
    }

    Binding {
        target: Services.NotificationService
        property: "integration"
        value: integration
        restoreMode: Binding.RestoreBindingOrValue
    }

    Notifications.NotificationPopupHost { id: popupHost }

    function owner(): string { return integration.owner; }
    function count(): int { return notificationCount; }
    function ids(): string { return JSON.stringify(receivedIds); }
    function historyCount(): int { return Services.NotificationService.history.length; }
    function popupCount(): int { return Services.NotificationService.popupNotifications.length; }
    function actionCount(): int {
        let count = 0;
        for (const record of Services.NotificationService.records)
            count = Math.max(count, record.data.actions.length);
        return count;
    }
    function actionReady(): bool { return lastActionId > 0 && lastActionIdentifier.length > 0; }
    function imagePath(): string { return lastImage; }
    function body(): string { return lastBody; }
    function invokeLastAction(): bool {
        return Services.NotificationService.invokeAction(lastActionId, lastActionIdentifier);
    }
    function invokeAction(identifier: string): bool {
        return Services.NotificationService.invokeAction(lastActionId, identifier);
    }
    function popupVisible(): bool { return popupHost.visible; }
    function reload(): bool {
        Quickshell.reload(false);
        return true;
    }

    IpcHandler {
        target: "qe-notification-test"
        function owner(): string { return root.owner(); }
        function count(): int { return root.count(); }
        function ids(): string { return root.ids(); }
        function historyCount(): int { return root.historyCount(); }
        function popupCount(): int { return root.popupCount(); }
        function actionCount(): int { return root.actionCount(); }
        function actionReady(): bool { return root.actionReady(); }
        function imagePath(): string { return root.imagePath(); }
        function body(): string { return root.body(); }
        function invokeLastAction(): bool { return root.invokeLastAction(); }
        function invokeAction(identifier: string): bool { return root.invokeAction(identifier); }
        function popupVisible(): bool { return root.popupVisible(); }
        function reload(): bool { return root.reload(); }
    }

    Connections {
        target: integration
        function onOwnerChanged() {
            if (integration.owner === "qe" && !root.ownerReported) {
                root.ownerReported = true;
                console.log("NOTIFICATION_OWNER_QE");
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        onTriggered: {
            console.error(`NOTIFICATION_INTEGRATION_TEST_FAILED: owner=${integration.owner}`);
            Qt.quit();
        }
    }
}
