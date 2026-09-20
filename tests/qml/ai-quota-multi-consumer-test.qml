import QtQuick
import Quickshell
import "services" as Services
import "fixtures/qml" as Fixtures
import "modules/bar" as BarModules
import "modules/aiquota" as AiQuotaModules

ShellRoot {
    id: root
    Fixtures.FakeAiQuotaAdapter { id: fake }
    Binding { target: Services.AiQuotaService; property: "adapter"; value: fake; restoreMode: Binding.RestoreBindingOrValue }
    QtObject { id: controller; function open(id, screen, side) {} function toggle(id, screen, side) {} }
    BarModules.AiQuotaModule { id: bar; dashboardController: controller; sourceScreen: "monitor-test"; visible: true }
    Loader {
        id: dashboardLoader
        active: false
        sourceComponent: AiQuotaModules.AiQuotaDashboard {}
        onLoaded: Qt.callLater(() => root.checkDashboard(item))
    }
    property bool done: false
    function fail(message) { console.error(`AI_QUOTA_MULTI_CONSUMER_TEST_FAILED: ${message}`); done = true; Qt.quit(); }
    function checkDashboard(dashboard) {
        if (Services.AiQuotaService.consumerCount !== 2 || !Services.AiQuotaService.polling)
            return root.fail(`bar and dashboard did not share active consumer state (${Services.AiQuotaService.consumerCount}, ${Services.AiQuotaService.polling}, bar=${bar.visible}, dashboard=${dashboard.visible})`);
        if (fake.requestReasons.length !== 1 || fake.requestReasons[0] !== "poll")
            return root.fail(`dashboard did not request one overdue poll from the existing bar consumer (${JSON.stringify(fake.requestReasons)})`);
        dashboardLoader.active = false;
        if (Services.AiQuotaService.consumerCount !== 1 || !Services.AiQuotaService.polling)
            return root.fail("polling stopped before the final consumer was removed");
        bar.visible = false;
        if (Services.AiQuotaService.consumerCount !== 0 || Services.AiQuotaService.polling)
            return root.fail("polling did not stop at zero consumers");
        console.log("AI_QUOTA_MULTI_CONSUMER_TEST_PASSED");
        root.done = true;
        Qt.quit();
    }
    Timer {
        interval: 100
        running: !root.done
        repeat: false
        onTriggered: {
            if (Services.AiQuotaService.consumerCount !== 1 || !Services.AiQuotaService.polling)
                return root.fail("bar did not establish the initial consumer");
            dashboardLoader.active = true;
        }
    }
    Timer { interval: 2500; running: !root.done; onTriggered: root.fail("test timed out") }
}
