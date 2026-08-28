import QtQuick
import Quickshell
import "services" as Services
import "fixtures/qml" as Fixtures

ShellRoot {
    id: root
    property bool started: false
    property bool done: false
    property bool actionInvoked: false
    property var fakeNotification

    Fixtures.FakeNotificationsIntegration { id: fakeIntegration }

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

        fakeNotification = {
            id: 1,
            appName: "Fixture",
            appIcon: "",
            summary: "First",
            body: "<b>Safe</b><script>ignored</script>",
            urgency: 1,
            actions: [{ identifier: "open", text: "Open", invoke: function() { root.actionInvoked = true; } }],
            image: "",
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
                || Services.NotificationService.popupNotifications.length !== 1)
            return fail("initial notification was not published");
        if (Services.NotificationService.history[0].data.body !== "<b>Safe</b>ignored")
            return fail("markup was not sanitized");
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

        fakeIntegration.close(fakeNotification, "dismissed");
        if (Services.NotificationService.popupNotifications.length !== 1)
            return fail("dismissal did not remove the popup");

        fakeIntegration.send({
            id: 4, appName: "Fixture", summary: "Reloaded", body: "Old", urgency: 1,
            actions: [], image: "", hints: {}, expireTimeout: 5, resident: false,
            transient: false, lastGeneration: true
        });
        if (Services.NotificationService.history.length !== 4
                || Services.NotificationService.popupNotifications.length !== 1)
            return fail("last-generation notification was re-shown");

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
