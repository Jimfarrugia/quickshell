import QtQuick
import Quickshell
import "integrations"
import "services" as Services

ShellRoot {
    id: root
    property bool started: false
    readonly property string expected: Quickshell.env("QE_TEST_EXTERNAL_STATUS")

    function fail(message) {
        console.error(`WALLPAPER_EXTERNAL_ADAPTER_TEST_FAILED: ${message}`);
        Qt.exit(1);
    }

    function begin() {
        if (started || adapter.availability !== "available") return;
        started = true;
        Services.WallpaperService.externalThemeAdapter = adapter;
        Services.WallpaperService.pendingExternalId = "adapter-test";
        Services.WallpaperService.externalThemeStatus = "pending";
        if (!adapter.apply(Quickshell.env("QE_TEST_EXTERNAL_RESULT"), "adapter-test"))
            fail("fixture request was rejected");
    }

    WallpaperExternalThemeAdapter {
        id: adapter
        timeoutMs: 100
        termGraceMs: 50
        onAvailabilityChanged: Qt.callLater(root.begin)
        onFinished: result => {
            if (result.operationId !== "adapter-test" || result.status !== root.expected
                    || result.contractValid !== (Quickshell.env("QE_TEST_EXTERNAL_VALID") === "1")
                    || result.success !== (root.expected !== "failed"))
                return root.fail(`unexpected result: ${JSON.stringify(result)}`);
            Qt.callLater(() => {
                if (Services.WallpaperService.externalThemeStatus !== root.expected
                        || Services.WallpaperService.pendingExternalId !== "")
                    return root.fail("service did not settle the external operation");
                console.log("WALLPAPER_EXTERNAL_ADAPTER_TEST_PASSED");
                Qt.quit();
            });
        }
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: root.fail("adapter did not publish a result")
    }

    Component.onCompleted: Qt.callLater(begin)
}
