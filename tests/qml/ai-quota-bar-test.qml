import QtQuick
import Quickshell
import "services" as Services
import "fixtures/qml" as Fixtures
import "modules/bar" as BarModules

ShellRoot {
    id: root
    Fixtures.FakeAiQuotaAdapter { id: fake }
    Binding { target: Services.AiQuotaService; property: "adapter"; value: fake; restoreMode: Binding.RestoreBindingOrValue }
    QtObject {
        id: controller
        property int opens: 0
        property int toggles: 0
        property var lastScreen: null
        function open(id, screen, side) { if (id === "ai-quota" && side === "left") { opens++; lastScreen = screen; } }
        function toggle(id, screen, side) { if (id === "ai-quota" && side === "left") { toggles++; lastScreen = screen; } }
        function isOpen(id) { return false; }
        function close() {}
    }
    BarModules.AiQuotaModule { id: module; dashboardController: controller; sourceScreen: "monitor-test" }
    property bool done: false
    function fail(message) { console.error(`AI_QUOTA_BAR_TEST_FAILED: ${message}`); done = true; Qt.quit(); }
    Timer {
        interval: 100
        running: !root.done
        repeat: false
        onTriggered: {
            Services.AiQuotaService.selectedProvider = "openai";
            if (module.icon !== "robot_2" || module.text !== "--") return root.fail("bar chip did not use the requested unavailable presentation");
            const provider = Services.AiQuotaService.provider("openai");
            Services.AiQuotaService.providers = Object.assign({}, Services.AiQuotaService.providers, {
                openai: Object.assign({}, provider, {
                    freshness: "stale",
                    weekly: Object.assign({}, provider.weekly, { status: "ok", remainingPercent: 75, freshness: "stale" })
                })
            });
            if (module.warning || module.border.width !== 0
                    || String(module.iconColor) !== String(Services.ThemeService.theme.tokens.warning)
                    || String(module.textColor) !== String(Services.ThemeService.theme.tokens.warning))
                return root.fail("stale bar chip did not use warning text/icon colors without a border");
            module.clicked();
            if (controller.opens !== 1 || controller.toggles !== 0 || controller.lastScreen !== "monitor-test") return root.fail("left click did not open the dashboard on the source monitor");
            module.secondaryClicked();
            if (Services.AiQuotaService.selectedProvider !== "opencode" || controller.toggles !== 0) return root.fail("right click did not only cycle the provider");
            console.log("AI_QUOTA_BAR_TEST_PASSED");
            root.done = true;
            Qt.quit();
        }
    }
    Timer { interval: 2500; running: !root.done; onTriggered: root.fail("test timed out") }
}
