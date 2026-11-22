import QtQuick
import Quickshell
import "services" as Services
import "components" as Components
import "fixtures/qml" as Fixtures
import "modules/bar" as BarModules

ShellRoot {
    id: root
    Fixtures.FakeAiQuotaAdapter { id: fake }
    Binding { target: Services.AiQuotaService; property: "adapter"; value: fake; restoreMode: Binding.RestoreBindingOrValue }
    Components.DashboardController { id: controller }
    Binding { target: Services.SurfaceService; property: "dashboardController"; value: controller; restoreMode: Binding.RestoreBindingOrValue }
    BarModules.AiQuotaModule { id: module; sourceScreen: "monitor-test" }
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
            Services.AiQuotaService.providers = Object.assign({}, Services.AiQuotaService.providers, {
                openai: Object.assign({}, Services.AiQuotaService.provider("openai"), {
                    freshness: "current"
                })
            });
            if (String(module.iconColor) !== String(Services.ThemeService.theme.tokens.on_surface_indicator)
                    || String(module.textColor) !== String(Services.ThemeService.theme.tokens.on_surface_subdued))
                return root.fail("current bar chip did not separate indicator and text emphasis");
            module.clicked();
            if (!controller.isOpen("ai-quota") || controller.sourceScreen !== "monitor-test" || controller.sourceSide !== "left")
                return root.fail("left click did not open the dashboard on the source monitor");
            module.secondaryClicked();
            if (Services.AiQuotaService.selectedProvider !== "opencode" || !controller.isOpen("ai-quota"))
                return root.fail("right click did not only cycle the provider");
            module.clicked();
            if (controller.visible) return root.fail("second left click did not close the dashboard");
            console.log("AI_QUOTA_BAR_TEST_PASSED");
            root.done = true;
            Qt.quit();
        }
    }
    Timer { interval: 2500; running: !root.done; onTriggered: root.fail("test timed out") }
}
