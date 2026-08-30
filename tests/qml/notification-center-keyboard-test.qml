import QtQuick
import Quickshell
import "services" as Services
import "modules/notifications" as Notifications

ShellRoot {
    id: root

    property int firstActionInvocations: 0
    property int secondActionInvocations: 0

    Notifications.NotificationCenter {
        id: center
        visible: false
    }

    function fail(message) {
        console.error(`NOTIFICATION_CENTER_KEYBOARD_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function record(id, actions) {
        return {
            data: {
                id: id,
                appName: "Fixture",
                summary: `Notification ${id}`,
                body: "Body",
                urgency: "normal",
                actions: actions,
                image: "",
                iconName: "notifications",
                isScreenshot: false,
                receivedAt: Date.now()
            },
            native: { actions: actions }
        };
    }

    function begin() {
        const firstActions = [
            { identifier: "first", text: "First", invoke: function() {
                root.firstActionInvocations++;
            } },
            { identifier: "second", text: "Second", invoke: function() {
                root.secondActionInvocations++;
            } }
        ];
        const records = [record(1, firstActions), record(2, []), record(3, [])];
        Services.NotificationService.records = records;
        Services.NotificationService.history = records;

        center.focusInitialTarget();
        if (center.focusRow !== 0 || center.focusedNotificationId !== 1
                || center.focusColumn !== -1 || center.focusedActionIdentifier !== "")
            return fail("the first notification card was not the initial focus target");

        center.focusHeader(0);
        center.handleNavigationKey(Qt.Key_L, Qt.NoModifier);
        center.handleNavigationKey(Qt.Key_L, Qt.NoModifier);
        center.handleNavigationKey(Qt.Key_L, Qt.NoModifier);
        if (center.focusRow !== -1 || center.focusColumn !== 2)
            return fail("header navigation did not clamp at the final control");
        center.handleNavigationKey(Qt.Key_H, Qt.NoModifier);
        if (center.focusColumn !== 1) return fail("h did not move within the header row");

        center.handleNavigationKey(Qt.Key_Return, Qt.NoModifier);
        if (!center.criticalFirst) return fail("Enter did not activate the focused header control");
        center.handleNavigationKey(Qt.Key_Space, Qt.NoModifier);
        if (center.criticalFirst) return fail("Space did not activate the focused header control");

        center.focusHeader(0);
        center.handleNavigationKey(Qt.Key_J, Qt.NoModifier);
        if (center.focusRow !== 0 || center.focusedNotificationId !== 1
                || center.focusColumn !== -1 || center.focusedActionIdentifier !== "")
            return fail("j did not focus the first card before its actions");
        center.handleNavigationKey(Qt.Key_L, Qt.NoModifier);
        if (center.focusedActionIdentifier !== "first")
            return fail("l did not move from the card to its first action");
        center.handleNavigationKey(Qt.Key_L, Qt.NoModifier);
        center.handleNavigationKey(Qt.Key_Return, Qt.NoModifier);
        center.handleNavigationKey(Qt.Key_Space, Qt.NoModifier);
        if (center.focusedActionIdentifier !== "second" || root.secondActionInvocations !== 2)
            return fail("card action navigation or activation was incorrect");

        center.handleNavigationKey(Qt.Key_J, Qt.NoModifier);
        if (center.focusRow !== 1 || center.focusedNotificationId !== 2
                || center.focusColumn !== -1)
            return fail("j did not focus the next actionless card");
        center.handleNavigationKey(Qt.Key_X, Qt.NoModifier);
        Qt.callLater(root.checkRemoval);
    }

    function checkRemoval() {
        if (Services.NotificationService.historyIndex(2) !== -1
                || center.focusedNotificationId !== 3 || center.focusRow !== 1)
            return fail("x did not remove the focused card and select its successor");
        center.handleNavigationKey(Qt.Key_K, Qt.NoModifier);
        center.handleNavigationKey(Qt.Key_K, Qt.NoModifier);
        if (center.focusRow !== -1)
            return fail("k did not return from the first card to the header");

        Services.SurfaceService.notificationCenterVisible = true;
        center.handleNavigationKey(Qt.Key_Escape, Qt.NoModifier);
        if (!Services.SurfaceService.notificationCenterVisible || center.keyboardCaptured)
            return fail("Escape did not release focus while preserving the notification center");
        center.handleNavigationKey(Qt.Key_Q, Qt.NoModifier);
        if (Services.SurfaceService.notificationCenterVisible)
            return fail("q did not close the notification center");

        console.log("NOTIFICATION_CENTER_KEYBOARD_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: root.fail("test timed out")
    }

    Component.onCompleted: Qt.callLater(begin)
}
