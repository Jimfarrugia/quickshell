import QtQuick
import Quickshell
import "services" as Services
import "modules/bar" as Bar
import "fixtures/qml" as Fixtures

ShellRoot {
    id: root

    QtObject { id: firstWindow }
    QtObject { id: secondWindow }
    Fixtures.FakeIdleInhibitorIntegration { id: fakeIntegration }
    Bar.IdleInhibitorModule { id: idleModule; visible: false }

    function fail(message) {
        console.error(`IDLE_SERVICE_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function runChecks() {
        if (!Services.ConfigService.hasLoaded) {
            retryTimer.restart();
            return;
        }
        Services.IdleService.integration = fakeIntegration;
        Services.IdleService.__windows = [];
        Services.IdleService.requested = false;
        Services.IdleService.updateIntegration();

        if (Services.IdleService.requested || Services.IdleService.setRequested(true))
            return fail("idle inhibition did not default off or accepted a request without a window");

        Services.IdleService.registerWindow(firstWindow);
        Services.IdleService.registerWindow(secondWindow);
        if (Services.IdleService.availability !== "available"
                || Services.IdleService.ownerWindow !== firstWindow)
            return fail("first registered window did not become the owner");
        if (!Services.IdleService.toggle() || !Services.IdleService.requested
                || !fakeIntegration.requested
                || idleModule.icon !== "visibility"
                || idleModule.active
                || idleModule.hoverText !== "Requested"
                || idleModule.iconColor.toString() !== Services.ThemeService.theme.tokens.primary.toString())
            return fail("idle request did not reach the native integration and presentation");

        Services.IdleService.unregisterWindow(firstWindow);
        if (Services.IdleService.ownerWindow !== secondWindow
                || !Services.IdleService.requested || !fakeIntegration.requested)
            return fail("request did not survive owner failover to another bar window");

        Services.IdleService.unregisterWindow(secondWindow);
        if (Services.IdleService.availability !== "unavailable"
                || Services.IdleService.requested || fakeIntegration.requested
                || idleModule.icon !== "visibility_off"
                || idleModule.hoverText !== "Disabled")
            return fail("last owner loss did not release the session request");

        Services.IdleService.registerWindow(firstWindow);
        Services.IdleService.setRequested(true);
        Services.ConfigService.applyText(JSON.stringify({
            schemaVersion: 1,
            bar: { enabled: true, idleInhibitorEnabled: false }
        }));
        if (Services.IdleService.requested || fakeIntegration.requested)
            return fail("disabling the configured module did not release the request");

        console.log("IDLE_SERVICE_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        id: retryTimer
        interval: 50
        repeat: false
        onTriggered: root.runChecks()
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: root.fail("test timed out")
    }

    Component.onCompleted: Qt.callLater(runChecks)
}
