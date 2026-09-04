import QtQuick
import Quickshell
import Quickshell.Io
import "services" as Services

ShellRoot {
    id: root
    property bool done: false
    readonly property string mode: Quickshell.env("QE_AI_QUOTA_TEST_MODE") || "read"
    function fail(message) { console.error(`AI_QUOTA_PERSISTENCE_TEST_FAILED: ${message}`); done = true; Qt.quit(); }
    Timer {
        interval: 500
        running: !root.done
        repeat: true
        onTriggered: {
            if (!Services.AiQuotaService.stateReady) return;
            if (root.mode === "write") {
                Services.AiQuotaService.selectedProvider = "openai";
                Services.AiQuotaService.cycleProvider();
                console.log("AI_QUOTA_PERSISTENCE_WRITE_PASSED");
            } else if (root.mode === "read") {
                if (Services.AiQuotaService.selectedProvider !== "opencode") return root.fail("provider selection did not survive restart");
                console.log("AI_QUOTA_PERSISTENCE_READ_PASSED");
            } else if (Services.AiQuotaService.selectedProvider !== "openai") {
                return root.fail("invalid persisted selection did not fall back to OpenAI");
            } else console.log("AI_QUOTA_PERSISTENCE_INVALID_PASSED");
            root.done = true;
            Qt.quit();
        }
    }
    Timer { interval: 2500; running: !root.done; onTriggered: root.fail("test timed out") }
}
