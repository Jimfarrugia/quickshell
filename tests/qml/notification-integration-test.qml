import QtQuick
import Quickshell
import Quickshell.Io
import "integrations" as Integrations
import "modules/notifications" as Notifications
import "services" as Services

ShellRoot {
    id: root
    property int notificationCount: 0
    property var receivedIds: []
    property bool ownerReported: false

    Integrations.NotificationsIntegration {
        id: integration
        active: true
        onNotificationReceived: notification => {
            root.notificationCount++;
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
