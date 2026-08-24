import QtQuick
import Quickshell
import "integrations" as Integrations

ShellRoot {
    id: root

    Integrations.NetworkAddressIntegration {
        id: addressIntegration
        onOperationChanged: {
            if (operation === "succeeded") {
                if (ipv4Address !== "127.0.0.1") root.fail(`unexpected loopback address '${ipv4Address}'`);
                else {
                    console.log("NETWORK_ADDRESS_TEST_PASSED");
                    Qt.quit();
                }
            } else if (operation === "failed") {
                root.fail(lastError ? lastError.detail : "lookup failed");
            }
        }
        Component.onCompleted: refresh("lo")
    }

    function fail(message) {
        console.error(`NETWORK_ADDRESS_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: root.fail("test timed out")
    }
}
