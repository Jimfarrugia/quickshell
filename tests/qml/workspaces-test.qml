import QtQuick
import Quickshell
import "services" as Services
import "fixtures/qml" as Fixtures

ShellRoot {
    id: root

    property var internalScreen: ({ name: "eDP-1" })
    property var externalScreen: ({ name: "HDMI-A-1" })
    property var workspaces: [
        ({ id: 1, name: "1", active: true, monitor: ({ name: "eDP-1" }), toplevels: ({ values: [] }) }),
        ({ id: 2, name: "2", active: false, monitor: ({ name: "eDP-1" }), toplevels: ({ values: [{}] }) }),
        ({ id: 3, name: "3", active: false, monitor: ({ name: "eDP-1" }), toplevels: ({ values: [] }) }),
        ({ id: 11, name: "11", active: false, monitor: ({ name: "HDMI-A-1" }), toplevels: ({ values: [{}] }) }),
        ({ id: -99, name: "special", active: true, monitor: ({ name: "eDP-1" }), toplevels: ({ values: [{}] }) })
    ]

    Fixtures.FakeCompositorIntegration {
        id: fakeCompositor
        monitorModel: ({ values: [{ name: "eDP-1" }, { name: "HDMI-A-1" }] })
        workspaceModel: root.workspaces
    }

    Binding {
        target: Services.CompositorService
        property: "integration"
        value: fakeCompositor
        restoreMode: Binding.RestoreBindingOrValue
    }

    property bool done: false
    property string resolvedInternalMonitor: Services.CompositorService.monitorNameForScreen(root.internalScreen)

    function fail(message) {
        console.error(`WORKSPACES_TEST_FAILED: ${message}`);
        done = true;
        Qt.quit();
    }

    function expectVisible(workspace, screen, expected, label) {
        const actual = Services.CompositorService.workspaceVisibleOnScreen(workspace, screen);
        if (actual !== expected) fail(`${label} visibility was ${actual}, expected ${expected}`);
    }

    function runChecks() {
        if (!Services.ConfigService.hasLoaded) {
            retryTimer.restart();
            return;
        }

        if (Services.CompositorService.monitorNameForScreen(root.internalScreen) !== "eDP-1")
            return fail("internal screen did not resolve to its monitor");
        if (Services.CompositorService.monitorNameForScreen(root.externalScreen) !== "HDMI-A-1")
            return fail("external screen did not resolve to its monitor");

        expectVisible(root.workspaces[0], root.internalScreen, true, "active internal workspace");
        expectVisible(root.workspaces[1], root.internalScreen, true, "occupied internal workspace");
        expectVisible(root.workspaces[2], root.internalScreen, false, "empty internal workspace");
        expectVisible(root.workspaces[3], root.internalScreen, false, "external workspace on internal screen");
        expectVisible(root.workspaces[4], root.internalScreen, false, "special workspace");
        expectVisible(root.workspaces[3], root.externalScreen, true, "occupied external workspace");
        expectVisible(root.workspaces[0], null, false, "workspace without a screen");

        if (!Services.CompositorService.activateWorkspace(root.workspaces[1])
                || fakeCompositor.lastActivatedWorkspace !== root.workspaces[1])
            return fail("workspace activation was not forwarded unchanged");

        fakeCompositor.monitorLookupAvailable = false;
        fakeCompositor.monitorModel = ({ values: [] });
        if (root.resolvedInternalMonitor !== "")
            return fail("missing monitor mapping did not clear the resolved monitor");
        expectVisible(root.workspaces[0], root.internalScreen, false, "workspace with missing monitor mapping");

        fakeCompositor.monitorLookupAvailable = true;
        fakeCompositor.monitorModel = ({ values: [{ name: "eDP-1" }] });
        if (root.resolvedInternalMonitor !== "eDP-1")
            return fail("monitor mapping did not recover after topology update");

        console.log("WORKSPACES_TEST_PASSED");
        done = true;
        Qt.quit();
    }

    Timer {
        id: retryTimer
        interval: 100
        repeat: false
        onTriggered: root.runChecks()
    }

    Timer {
        interval: 2500
        running: !root.done
        onTriggered: root.fail("test timed out")
    }

    Component.onCompleted: Qt.callLater(runChecks)
}
