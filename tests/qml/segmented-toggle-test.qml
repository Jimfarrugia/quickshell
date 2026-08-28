import QtQuick
import Quickshell
import "components" as Components
import "services" as Services

ShellRoot {
    id: root

    property int toggleCount: 0

    function fail(message) {
        console.error(`SEGMENTED_TOGGLE_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function childWithName(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const match = childWithName(child, name);
            if (match !== null) return match;
        }
        return null;
    }

    function check() {
        const first = childWithName(toggle, "segment-0");
        const second = childWithName(toggle, "segment-1");
        if (first === null || second === null)
            return fail("binary segments were not created");
        if (Math.abs(first.width - toggle.width / 2) > 0.01
                || Math.abs(second.width - toggle.width / 2) > 0.01)
            return fail("segments do not divide the available width equally");
        if (Math.abs(first.x) > 0.01 || Math.abs(second.x - first.width) > 0.01)
            return fail("segments overlap or leave an outer gap");
        if (!Qt.colorEqual(first.children[0].color, Services.ThemeService.theme.tokens.primary)
                || !Qt.colorEqual(second.children[0].color,
                    Services.ThemeService.theme.tokens.surface_variant))
            return fail("unchecked segment colors are incorrect");

        toggle.checked = true;
        if (!Qt.colorEqual(first.children[0].color, Services.ThemeService.theme.tokens.surface_variant)
                || !Qt.colorEqual(second.children[0].color, Services.ThemeService.theme.tokens.primary))
            return fail("checked segment colors are incorrect");

        toggle.activate();
        if (root.toggleCount !== 1)
            return fail("activation did not emit exactly one toggle request");
        if (!toggle.activeFocus)
            return fail("activation did not focus the toggle");

        console.log("SEGMENTED_TOGGLE_TEST_PASSED");
        Qt.quit();
    }

    FloatingWindow {
        visible: true
        implicitWidth: 240
        implicitHeight: 38

        Components.SegmentedToggle {
            id: toggle
            anchors.fill: parent
            labels: ["First", "Second"]
            onToggled: root.toggleCount += 1
        }
    }

    Timer {
        interval: 50
        running: true
        onTriggered: root.check()
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail("segmented toggle test timed out")
    }
}
