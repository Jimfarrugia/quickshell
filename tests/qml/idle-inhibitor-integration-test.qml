import QtQuick
import Quickshell
import "integrations" as Integrations

ShellRoot {
    id: root

    property int enabledTransitions: 0

    PanelWindow {
        id: ownerWindow
        visible: true
        implicitWidth: 1
        implicitHeight: 1
    }

    Integrations.IdleInhibitorIntegration {
        id: integration
    }

    Connections {
        target: integration.inhibitor
        function onEnabledChanged() { root.enabledTransitions += 1; }
    }

    function fail(message) {
        console.error(`IDLE_INHIBITOR_INTEGRATION_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    Timer {
        interval: 300
        running: true
        onTriggered: {
            if (!integration.inhibitor.enabled || root.enabledTransitions < 3)
                return root.fail("startup request was not re-armed");
            integration.requested = false;
            if (integration.inhibitor.enabled)
                return root.fail("disabled request did not release the inhibitor");
            console.log("IDLE_INHIBITOR_INTEGRATION_TEST_PASSED");
            Qt.quit();
        }
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: root.fail("test timed out")
    }

    Component.onCompleted: {
        integration.ownerWindow = ownerWindow;
        integration.requested = true;
    }
}
