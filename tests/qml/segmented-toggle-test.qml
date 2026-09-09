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

    function textChild(item) {
        for (const child of item.children) {
            if (child.text !== undefined) return child;
        }
        return null;
    }

    function check() {
        const first = childWithName(toggle, "segment-0");
        const second = childWithName(toggle, "segment-1");
        if (first === null || second === null)
            return fail("binary segments were not created");
        const firstText = textChild(first);
        const secondText = textChild(second);
        if (firstText === null || secondText === null)
            return fail("binary segment labels were not created");
        if (Math.abs(first.width - toggle.width / 2) > 0.01
                || Math.abs(second.width - toggle.width / 2) > 0.01)
            return fail("segments do not divide the available width equally");
        if (Math.abs(first.x) > 0.01 || Math.abs(second.x - first.width) > 0.01)
            return fail("segments overlap or leave an outer gap");
        if (!Qt.colorEqual(first.children[0].color,
                Services.ThemeService.theme.tokens.primary_container)
                || !Qt.colorEqual(firstText.color,
                    Services.ThemeService.theme.tokens.on_primary_container)
                || !Qt.colorEqual(second.children[0].color,
                    Services.ThemeService.theme.tokens.surface_variant))
            return fail("unchecked segment colors are incorrect");

        toggle.checked = true;
        if (!Qt.colorEqual(first.children[0].color, Services.ThemeService.theme.tokens.surface_variant)
                || !Qt.colorEqual(second.children[0].color,
                    Services.ThemeService.theme.tokens.primary_container)
                || !Qt.colorEqual(secondText.color,
                    Services.ThemeService.theme.tokens.on_primary_container))
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
            onToggled: function(checked) {
                root.toggleCount += 1;
                toggle.checked = checked;
            }
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
