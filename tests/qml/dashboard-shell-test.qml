import QtQuick
import Quickshell
import Quickshell as QS

ShellRoot {
    id: root

    Loader {
        id: controllerLoader
        source: "components/DashboardController.qml"
        onLoaded: root.begin(item)
    }

    QS.LazyLoader {
        id: shellLoader
        active: false
        source: "components/DashboardShell.qml"
        onItemChanged: if (item) Qt.callLater(() => root.checkShell(item))
    }
    Component {
        id: fixtureDashboard
        Text { text: "Fixture dashboard" }
    }
    function calculate(width, height, contentHeight, barEnabled, barEdge, barHeight, side) {
        const inset = 20;
        const gap = barEnabled ? Number(barHeight) + inset : inset;
        const available = Math.max(0, Number(height) - gap - inset);
        const resultHeight = Math.min(available, Math.max(0, Number(contentHeight) + inset * 2));
        const resultWidth = Math.min(636, Math.max(0, Number(width) - inset * 2));
        return { left: side === "left" ? inset : Number(width) - inset - resultWidth,
            top: barEdge === "top" ? gap : Number(height) - gap - resultHeight,
            width: resultWidth, height: resultHeight, contentInset: inset };
    }
    function fail(message) {
        console.error(`DASHBOARD_SHELL_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function begin(controller) {
        const bottom = calculate(1200, 900, 580,
            true, "bottom", 26, "right");
        if (bottom.width !== 636 || bottom.contentInset !== 20
                || bottom.top !== 234 || bottom.height !== 620)
            return fail("bottom geometry did not preserve bounds and width");

        const top = calculate(800, 600, 100,
            true, "top", 30, "left");
        if (top.left !== 20 || top.top !== 50 || top.width !== 636 || top.height !== 140)
            return fail("top geometry did not follow the top bar");

        const narrow = calculate(300, 500, 100,
            false, "bottom", 0, "right");
        if (narrow.width !== 260 || narrow.left !== 20 || narrow.top !== 340)
            return fail("narrow or no-bar geometry was incorrect");

        controller.open("audio", "monitor-2", "right");
        if (!controller.visible || controller.activeId !== "audio"
                || controller.sourceScreen !== "monitor-2")
            return fail("dashboard open did not retain source routing");
        controller.open("network", "monitor-3", "left");
        if (controller.activeId !== "network" || controller.sourceScreen !== "monitor-3")
            return fail("opening a dashboard did not replace the active slot");
        controller.toggle("network", "monitor-3", "left");
        if (controller.visible)
            return fail("source toggle did not close the active dashboard");

        root.controller = controller;
        controller.open("fixture", null, "right");
        shellLoader.active = true;

    }

    property var controller

    function checkShell(shell) {
        shell.controller = controller;
        shell.contentComponent = fixtureDashboard;
        if (!shell.focusable || !shell.keyboardTargetRequested)
            return fail("dashboard shell did not request keyboard focus");
        shell.viewportWidth = 1200;
        shell.viewportHeight = 900;
        shell.testBarEnabled = true;
        shell.testBarEdge = "bottom";
        shell.testBarHeight = 26;
        shell.contentHeightOverride = 580;
        controller.open("fixture", "monitor-1", "right");
        shell.dismissFromEscape();
        if (controller.visible)
            return fail("Escape dismissal did not close the controller");
        controller.open("fixture", "monitor-1", "right");
        shell.dismissFromOutside();
        if (controller.visible)
            return fail("outside dismissal did not close the controller");
        controller.open("fixture", "monitor-1", "right");
        if (shell.surfaceWidth !== 636 || shell.surfaceHeight !== 620
                || shell.surfaceX !== 544 || shell.surfaceY !== 234)
            return fail("instantiated shell did not expose expected bottom geometry");

        shell.testBarEdge = "top";
        shell.testBarHeight = 30;
        shell.contentHeightOverride = 100;
        controller.sourceSide = "left";
        if (shell.surfaceX !== 20 || shell.surfaceY !== 50
                || shell.surfaceHeight !== 140)
            return fail("instantiated shell did not follow top-bar geometry");

        shell.testBarEnabled = false;
        shell.viewportWidth = 300;
        shell.viewportHeight = 500;
        shell.testBarEdge = "bottom";
        if (shell.surfaceWidth !== 260 || shell.surfaceX !== 20
                || shell.surfaceY !== 340)
            return fail("instantiated shell did not constrain narrow no-bar output");

        controller.close();
        if (controller.visible || controller.activeId !== "")
            return fail("dashboard controller did not close the shell state");

        shellLoader.active = false;
        if (shellLoader.item !== null)
            return fail("lazy loader did not destroy the dashboard shell");

        console.log("DASHBOARD_SHELL_TEST_PASSED");
        Qt.quit();
    }

    Timer { interval: 3000; running: true; onTriggered: fail("test timed out") }
}
