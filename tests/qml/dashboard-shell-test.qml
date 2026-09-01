import QtQuick
import Quickshell
import "../../services" as Services

ShellRoot {
    QtObject {
        id: controller
        property bool visible: false
        property string activeId: ""
        property var sourceScreen: null
        property string sourceSide: "right"
        function open(id, screen, side) { activeId = id; sourceScreen = screen; sourceSide = side; visible = true; }
        function close() { visible = false; }
        function toggle(id, screen, side) { visible && activeId === id ? close() : open(id, screen, side); }
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

    function begin() {
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

        console.log("DASHBOARD_SHELL_TEST_PASSED");
        Qt.quit();
    }

    Timer { interval: 3000; running: true; onTriggered: fail("test timed out") }
    Component.onCompleted: Qt.callLater(begin)
}
