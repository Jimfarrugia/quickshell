import QtQuick
import Quickshell
import "services" as Services
import "modules/bar" as Bar
import "fixtures/qml" as Fixtures
import "utils/Notifications.mjs" as Notifications

ShellRoot {
    id: root
    property bool started: false
    property bool done: false
    property bool actionInvoked: false
    property var fakeNotification

    Fixtures.FakeNotificationsIntegration { id: fakeIntegration }
    Bar.DoNotDisturbModule { id: dndModule; visible: false }

    function fail(message) {
        if (done) return;
        console.error(`NOTIFICATION_SERVICE_TEST_FAILED: ${message}`);
        done = true;
        testTimer.stop();
        Qt.quit();
    }

    function begin() {
        if (done || started || !Services.NotificationService.stateReady) return;
        started = true;
        Services.NotificationService.integration = fakeIntegration;

        Services.NotificationService.setDnd(false);
        if (dndModule.icon !== "do_not_disturb_off"
                || dndModule.hoverText !== "Do not disturb disabled"
                || dndModule.iconColor.toString() !== Services.ThemeService.theme.tokens.secondary.toString())
            return fail("disabled DND bar presentation was incorrect");
        dndModule.clicked();
        if (!Services.NotificationService.dnd
                || dndModule.icon !== "do_not_disturb_on"
                || dndModule.hoverText !== "Do not disturb enabled"
                || dndModule.iconColor.toString() !== Services.ThemeService.theme.tokens.warning.toString())
            return fail("DND bar button did not enable DND or update presentation");
        dndModule.clicked();
        if (Services.NotificationService.dnd)
            return fail("DND bar button did not disable DND");

        fakeNotification = {
            id: 1,
            appName: "Fixture",
            appIcon: "",
            summary: "First",
            body: "<b>Safe</b><script>ignored</script>",
            urgency: 1,
            actions: [{ identifier: "open", text: "Open", invoke: function() { root.actionInvoked = true; } }],
            image: "file:///tmp/qe-notification.png",
            hints: { value: 40 },
            expireTimeout: 5,
            resident: true,
            transient: false,
            lastGeneration: false,
            dismiss: function() { fakeIntegration.close(this, "dismissed"); },
            expire: function() { fakeIntegration.close(this, "expired"); }
        };
        fakeIntegration.send(fakeNotification);
        if (Services.NotificationService.history.length !== 1
                || Services.NotificationService.popupNotifications.length !== 1
                || Services.NotificationService.popupExpirations[1] === undefined)
            return fail("initial notification was not published");
        if (Services.NotificationService.history[0].data.body !== "<b>Safe</b>ignored")
            return fail("markup was not sanitized");
        if (Services.NotificationService.history[0].data.image !== fakeNotification.image)
            return fail("local notification image was not normalized");
        if (!Number.isFinite(Services.NotificationService.history[0].data.receivedAt))
            return fail("notification receive time was not recorded");
        if (Services.NotificationService.history[0].data.iconName !== "notifications")
            return fail("normal notification fallback icon was not selected");
        if (Notifications.normalizeNotification({ appName: "Other", urgency: 2 }).iconName !== "warning")
            return fail("critical notification fallback icon was not selected");
        if (Notifications.normalizeNotification({ appName: "OpenCode", urgency: 1 }).iconName !== "robot_2")
            return fail("OpenCode notification icon was not selected");
        if (!Notifications.normalizeNotification({
                appName: "Hyprshot", image: "file:///tmp/screenshot.png" }).isScreenshot)
            return fail("Hyprshot screenshot notification was not identified");
        if (!Services.NotificationService.history[0].data.hasProgress
                || Services.NotificationService.history[0].data.progress !== 40)
            return fail("progress was not normalized");
        if (!Services.NotificationService.invokeAction(1, "open") || !actionInvoked)
            return fail("notification action was not invoked");

        fakeNotification.summary = "Replacement";
        fakeIntegration.update(fakeNotification);
        if (Services.NotificationService.history.length !== 1
                || Services.NotificationService.history[0].data.summary !== "Replacement")
            return fail("replacement duplicated or failed to update history");

        Services.NotificationService.setDnd(true);
        const suppressed = {
            id: 2, appName: "Fixture", summary: "Suppressed", body: "Normal", urgency: 1,
            actions: [], image: "", hints: {}, expireTimeout: 5, resident: false,
            transient: false, lastGeneration: false
        };
        fakeIntegration.send(suppressed);
        if (Services.NotificationService.popupNotifications.length !== 1
                || Services.NotificationService.history.length !== 2)
            return fail("DND did not suppress a normal popup while retaining history");

        fakeIntegration.send({
            id: 3, appName: "Fixture", summary: "Critical", body: "Alert", urgency: 2,
            actions: [], image: "", hints: {}, expireTimeout: 0, resident: false,
            transient: false, lastGeneration: false
        });
        if (Services.NotificationService.popupNotifications.length !== 2)
            return fail("DND suppressed a critical popup");
        if (Services.NotificationService.popupExpirations[3] !== undefined)
            return fail("critical notification was scheduled for automatic expiry");

        fakeIntegration.close(fakeNotification, "dismissed");
        if (Services.NotificationService.popupNotifications.length !== 1
                || Services.NotificationService.history.length !== 3)
            return fail("dismissal did not remove the popup while retaining history");

        if (!Services.NotificationService.setPopupsBlocked(true)
                || Services.NotificationService.popupNotifications.length !== 0)
            return fail("blocking popup presentation did not clear visible popups");
        fakeIntegration.send({
            id: 5, appName: "Fixture", summary: "Blocked", body: "Critical blocked", urgency: 2,
            actions: [], image: "", hints: {}, expireTimeout: 0, resident: false,
            transient: false, lastGeneration: false
        });
        if (Services.NotificationService.popupNotifications.length !== 0
                || Services.NotificationService.history.length !== 4)
            return fail("blocked notification was presented or not retained in history");
        Services.NotificationService.setPopupsBlocked(false);

        Services.NotificationService.popupNotifications = [{ data: fakeNotification, native: fakeNotification }];
        Services.NotificationService.popupExpirations = ({ 1: Date.now() - 1 });
        Services.NotificationService.expireDuePopups();
        if (Services.NotificationService.popupNotifications.length !== 0
                || !Services.NotificationService.invokeAction(1, "open"))
            return fail("action notification was not retained after popup expiry");

        fakeIntegration.send({
            id: 4, appName: "Fixture", summary: "Reloaded", body: "Old", urgency: 1,
            actions: [], image: "", hints: {}, expireTimeout: 5, resident: false,
            transient: false, lastGeneration: true
        });
        if (Services.NotificationService.history.length !== 5
                || Services.NotificationService.popupNotifications.length !== 0)
            return fail("last-generation notification was re-shown");
        if (!Services.NotificationService.removeFromHistory(5)
                || Services.NotificationService.history.length !== 4
                || Services.NotificationService.historyIndex(5) !== -1)
            return fail("individual history removal failed");
        if (Services.NotificationService.removeFromHistory(5))
            return fail("individual history removal succeeded for a missing notification");

        done = true;
        testTimer.stop();
        console.log("NOTIFICATION_SERVICE_TEST_PASSED");
        Qt.quit();
    }

    Connections {
        target: Services.NotificationService
        function onStateReadyChanged() { root.begin(); }
    }

    Timer {
        id: testTimer
        interval: 4000
        running: true
        onTriggered: root.fail("notification service test timed out")
    }

    Component.onCompleted: {
        Services.NotificationService.stateReady = true;
        begin();
    }
}
