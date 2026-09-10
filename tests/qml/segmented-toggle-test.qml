import QtQuick
import Quickshell
import "components" as Components

ShellRoot {
    id: root

    property int toggleCount: 0
    property bool lastRequestedState: false

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
        if (firstText === null || secondText === null
                || firstText.text !== "First" || secondText.text !== "Second")
            return fail("binary segment labels were not projected");

        toggle.activate(true);
        if (root.toggleCount !== 1 || !root.lastRequestedState || !toggle.checked)
            return fail("activation did not request and apply the selected state exactly once");
        if (!toggle.activeFocus)
            return fail("activation did not focus the toggle");

        toggle.activate(false);
        if (root.toggleCount !== 2 || root.lastRequestedState || toggle.checked)
            return fail("explicit activation did not request and apply the unselected state");

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
                root.lastRequestedState = checked;
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
