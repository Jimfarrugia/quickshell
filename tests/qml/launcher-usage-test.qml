import QtQuick
import Quickshell
import "utils/Launcher.mjs" as Launcher

ShellRoot {
    Timer {
        interval: 0
        running: true
        onTriggered: {
            const usage = Launcher.validateUsage({
                schemaVersion: 1,
                entries: {
                    first: { launchCount: 3 },
                    second: { launchCount: 1 }
                }
            });
            if (usage === null || usage.first?.launchCount !== 3
                    || usage.second?.launchCount !== 1) {
                console.error("LAUNCHER_USAGE_TEST_FAILED: valid persisted usage was rejected");
                Qt.quit();
                return;
            }
            console.log("LAUNCHER_USAGE_TEST_PASSED");
            Qt.quit();
        }
    }
}
