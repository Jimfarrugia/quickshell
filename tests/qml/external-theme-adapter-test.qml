import QtQuick
import Quickshell
import "integrations"

ShellRoot {
    id: root

    readonly property string expected: Quickshell.env("EXPECT_EXTERNAL")
    property bool started: false
    property bool stateUpdated: false

    function pass() {
        console.log(`EXTERNAL_THEME_ADAPTER_${expected.toUpperCase()}_PASSED`);
        Qt.quit();
    }

    function fail(message) {
        console.error(`EXTERNAL_THEME_ADAPTER_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function begin() {
        if (expected === "unavailable") {
            if (adapter.availability === "unavailable") pass();
            return;
        }
        if (expected === "daemon-loss") {
            if (adapter.availability === "available")
                console.log("EXTERNAL_THEME_ADAPTER_READY");
            else if (adapter.availability === "unavailable") pass();
            return;
        }
        if (expected === "invalid-id") {
            if (adapter.availability === "available" && !adapter.start("../gruvbox", "adapter-invalid"))
                pass();
            return;
        }
        if (expected === "state") {
            if (adapter.availability === "available")
                console.log("EXTERNAL_THEME_ADAPTER_READY");
            return;
        }
        if (!started && adapter.availability === "available") {
            started = true;
            if (!adapter.start("gruvbox", `adapter-${expected}`))
                fail("adapter rejected a valid fixture request");
        }
    }

    ExternalThemeAdapter {
        id: adapter
        executable: Quickshell.env("QE_THEME_SWITCHER")
        timeoutMs: 100
        termGraceMs: 50

        onAvailabilityChanged: root.begin()
        onLastStateChanged: {
            if (root.expected !== "state" || lastState === null) return;
            if (lastState.requestedTheme !== "poimandres") return;
            if (lastState.status !== "success")
                return root.fail("independent state update was not normalized");
            root.stateUpdated = true;
            console.log("EXTERNAL_THEME_ADAPTER_STATE_READY");
        }
        onLastErrorChanged: {
            if (root.expected !== "state" || !root.stateUpdated || lastError === null) return;
            if (!lastError.includes("malformed") || lastState.requestedTheme !== "poimandres")
                return root.fail("malformed state did not retain the last-known-good result");
            root.pass();
        }
        onFinished: result => {
            if (root.expected === "success" && result.contractValid && result.status === "success")
                return root.pass();
            if (root.expected === "partial" && result.contractValid && result.status === "partial"
                    && result.targets.length === 2)
                return root.pass();
            if (root.expected === "malformed" && !result.contractValid && !result.timedOut)
                return root.pass();
            if (root.expected === "timeout" && !result.contractValid && result.timedOut
                    && result.error.includes("timed out"))
                return root.pass();
            root.fail(`unexpected result for ${root.expected}: ${JSON.stringify(result)}`);
        }
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail(`${root.expected} fixture timed out`)
    }

    Component.onCompleted: begin()
}
