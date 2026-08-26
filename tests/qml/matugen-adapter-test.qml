import QtQuick
import Quickshell
import "integrations"

ShellRoot {
    id: root

    property bool requested: false
    readonly property string imagePath: Quickshell.env("QE_TEST_WALLPAPER") || "/tmp/qe-matugen-wallpaper.png"

    MatugenAdapter {
        id: adapter
        executable: Quickshell.env("QE_MATUGEN")
    }

    function begin() {
        if (requested || adapter.availability !== "available") return;
        requested = true;
        if (!adapter.generate(root.imagePath, "dark", "matugen-test"))
            fail("adapter rejected a valid generation request");
    }

    function fail(message) {
        console.error(`MATUGEN_ADAPTER_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    Connections {
        target: adapter
        function onAvailabilityChanged() { root.begin(); }
        function onFinished(result) {
            if (!result.success) return root.fail(result.error);
            if (result.operationId !== "matugen-test" || result.theme.id !== "wallpaper")
                return root.fail("adapter returned an invalid mapped theme");
            if (!/^#[0-9a-f]{6}$/.test(result.theme.tokens.primary))
                return root.fail("adapter did not return a normalized Matugen color");
            console.log("MATUGEN_ADAPTER_TEST_PASSED");
            Qt.quit();
        }
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail("Matugen adapter test timed out")
    }

    Component.onCompleted: begin()
}
