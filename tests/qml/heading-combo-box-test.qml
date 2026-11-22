import QtQuick
import QtTest
import Quickshell
import "components" as Components

ShellRoot {
    id: root

    property var options: [
        { id: "a", name: "Alpha" },
        { id: "b", name: "Beta" },
        { id: "c", name: "Gamma" }
    ]
    // The host owns the selection, exactly as the palette and wallpaper selectors do.
    property string hostSelection: "a"
    property int dismissCount: 0
    property int leaveCount: 0
    property var selections: []
    property int stepIndex: 0

    function fail(message) {
        stepTimer.stop();
        console.error(`HEADING_COMBO_BOX_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function key(code, modifiers) {
        if (!keys.keyClick(code, modifiers === undefined ? Qt.NoModifier : modifiers, -1))
            fail("key event could not be delivered");
    }

    function expectCounts(dismissed, left, message) {
        if (root.dismissCount !== dismissed || root.leaveCount !== left)
            return fail(`${message} (dismiss ${root.dismissCount}, leaveDown ${root.leaveCount})`);
        return true;
    }

    // Each step runs after the previous one's popup and focus changes have settled.
    readonly property var steps: [
        function() {
            combo.forceActiveFocus();
        },
        function() {
            if (!combo.activeFocus)
                return fail("combo did not take keyboard focus in the test window");
            if (combo.displayText !== "Theme: Alpha")
                return fail(`display text did not combine prefix and selection: ${combo.displayText}`);
            root.hostSelection = "c";
            if (combo.displayText !== "Theme: Gamma")
                return fail("selectedId did not drive the displayed option");
            root.hostSelection = "a";

            // Closed: h and k are inert; j leaves downward; q and Escape dismiss.
            root.key(Qt.Key_H);
            root.key(Qt.Key_K);
            if (!root.expectCounts(0, 0, "h or k emitted a signal with the popup closed")) return;
            root.key(Qt.Key_J, Qt.ShiftModifier);
            root.key(Qt.Key_Q, Qt.ControlModifier);
            if (!root.expectCounts(0, 0, "a modified vim key was treated as an alias")) return;
            root.key(Qt.Key_J);
            if (!root.expectCounts(0, 1, "j did not request leaving downward")) return;
            root.key(Qt.Key_Q);
            if (!root.expectCounts(1, 1, "q did not request dismissal")) return;
            root.key(Qt.Key_Escape);
            if (!root.expectCounts(2, 1, "Escape did not request dismissal")) return;
            if (combo.popup.visible)
                return fail("dismissal keys opened the popup");
            root.key(Qt.Key_L);
        },
        function() {
            if (!combo.popup.visible)
                return fail("l did not open the popup");
            if (!combo.popup.contentItem.activeFocus)
                return fail("opening the popup did not move focus into the option list");
            // Escape closes only the popup; the surface stays.
            root.key(Qt.Key_Escape);
            if (combo.popup.visible)
                return fail("Escape did not close the open popup");
            if (!root.expectCounts(2, 1, "Escape in the open popup requested dismissal")) return;
        },
        function() {
            if (!combo.activeFocus)
                return fail("focus did not return to the combo after the popup closed");
            // A full Enter tap opens the popup; the release must not undo that.
            root.key(Qt.Key_Return);
        },
        function() {
            if (!combo.popup.visible)
                return fail("an Enter tap did not leave the popup open");
            root.key(Qt.Key_Escape);
        },
        function() {
            // Held Enter: the release arrives after focus moved into the list.
            keys.keyPress(Qt.Key_Return, Qt.NoModifier, -1);
        },
        function() {
            keys.keyRelease(Qt.Key_Return, Qt.NoModifier, -1);
            if (!combo.popup.visible)
                return fail("Enter's release closed the popup it had just opened");
            // h closes without selecting; navigation clamps at the first option.
            root.key(Qt.Key_K);
            root.key(Qt.Key_H);
            if (combo.popup.visible)
                return fail("h did not close the popup");
            if (root.selections.length !== 0)
                return fail("closing the popup with h selected an option");
        },
        function() {
            root.key(Qt.Key_L);
        },
        function() {
            // k clamps on Alpha; j, j, j clamps on Gamma; k returns to Beta; l selects it.
            root.key(Qt.Key_K);
            root.key(Qt.Key_J);
            root.key(Qt.Key_J);
            root.key(Qt.Key_J);
            root.key(Qt.Key_K);
            root.key(Qt.Key_L);
            if (combo.popup.visible)
                return fail("l did not close the popup after selecting");
            if (root.selections.join() !== "b")
                return fail(`vim navigation selected ${root.selections.join()} instead of b`);
            if (root.hostSelection !== "b" || combo.displayText !== "Theme: Beta")
                return fail("selection did not round-trip through the host back into selectedId");
        },
        function() {
            // Enter selects the highlighted option; its release must not reopen the popup.
            root.key(Qt.Key_L);
        },
        function() {
            root.key(Qt.Key_K);
            root.key(Qt.Key_K);
            root.key(Qt.Key_K);
            root.key(Qt.Key_J);
            root.key(Qt.Key_J);
            root.key(Qt.Key_Return);
            if (combo.popup.visible)
                return fail("Enter did not close the popup after selecting");
            if (root.selections.join() !== "b,c")
                return fail(`Enter selected ${root.selections.join()} instead of b,c`);
        },
        function() {
            if (combo.popup.visible)
                return fail("Enter's release reopened the popup");
            if (!combo.activeFocus)
                return fail("focus did not return to the combo after Enter selection");
            // A late release that lands on the refocused combo must not reopen it either.
            keys.keyRelease(Qt.Key_Return, Qt.NoModifier, -1);
            if (combo.popup.visible)
                return fail("a late Enter release reopened the popup");
            root.key(Qt.Key_L);
        },
        function() {
            if (!combo.popup.visible)
                return fail("popup did not reopen");
            // Clicking an option selects it through the same signal.
            const option = combo.popup.contentItem.itemAtIndex(0);
            if (!keys.mouseClick(option, option.width / 2, option.height / 2, Qt.LeftButton, Qt.NoModifier, -1))
                return fail("mouse click could not be delivered");
            if (root.selections.join() !== "b,c,a" || root.hostSelection !== "a")
                return fail(`clicking an option selected ${root.selections.join()}`);
            // q inside the open popup still dismisses the whole surface.
            root.key(Qt.Key_L);
        },
        function() {
            if (!combo.popup.visible)
                return fail("popup did not reopen after a click selection");
            root.key(Qt.Key_Q);
            if (!root.expectCounts(3, 1, "q in the open popup did not request dismissal")) return;
            console.log("HEADING_COMBO_BOX_TEST_PASSED");
            Qt.quit();
        }
    ]

    function advance() {
        if (root.stepIndex >= root.steps.length) return;
        root.steps[root.stepIndex++]();
    }

    TestEvent { id: keys }

    FloatingWindow {
        visible: true
        implicitWidth: 360
        implicitHeight: 260

        Components.HeadingComboBox {
            id: combo
            x: 10
            y: 10
            model: root.options
            selectedId: root.hostSelection
            prefix: "Theme"
            onSelected: value => {
                root.selections = root.selections.concat([value]);
                root.hostSelection = value;
            }
            onDismissRequested: root.dismissCount += 1
            onLeaveDown: root.leaveCount += 1
        }
    }

    Timer {
        id: stepTimer
        interval: 60
        repeat: true
        running: true
        onTriggered: root.advance()
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail("heading combo box test timed out")
    }
}
