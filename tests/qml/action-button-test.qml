import QtQuick
import Quickshell
import "components" as Components
import "services" as Services

ShellRoot {
    id: root

    function fail(message) {
        console.error(`ACTION_BUTTON_TEST_FAILED: ${message}`);
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

    function contentIsCentered(control) {
        const content = childWithName(control, "action-content");
        if (content === null) return false;
        const center = content.mapToItem(control, content.width / 2, content.height / 2);
        return Math.abs(center.x - control.width / 2) <= 0.5
            && Math.abs(center.y - control.height / 2) <= 0.5;
    }

    function check() {
        const icon = childWithName(iconButton, "action-icon");
        if (icon === null) return fail("icon content was not created");
        const iconCenter = icon.mapToItem(iconButton, icon.width / 2, icon.height / 2);
        if (Math.abs(iconCenter.x - iconButton.width / 2) > 0.5
                || Math.abs(iconCenter.y - iconButton.height / 2) > 0.5)
            return fail(`IconButton content center ${iconCenter} does not match its button center`);
        if (!contentIsCentered(groupedButton))
            return fail("icon and text group is not centered in ActionButton");

        if (!Qt.colorEqual(button.resolvedForegroundColor,
                Services.ThemeService.theme.tokens.on_surface_subdued)
                || !Qt.colorEqual(button.resolvedBorderColor,
                    Services.ThemeService.theme.tokens.outline_variant))
            return fail("neutral button does not use subdued enabled styling");

        button.checkable = true;
        button.checked = true;
        if (!Qt.colorEqual(button.resolvedBackgroundColor,
                Services.ThemeService.theme.tokens.primary_container)
                || !Qt.colorEqual(button.resolvedForegroundColor,
                    Services.ThemeService.theme.tokens.on_primary_container))
            return fail("checked button does not use the selection pair");

        button.checked = false;
        button.enabled = false;
        if (!Qt.colorEqual(button.resolvedForegroundColor,
                Services.ThemeService.theme.tokens.on_surface_disabled))
            return fail("disabled button does not use disabled content styling");

        button.pending = true;
        if (!Qt.colorEqual(button.resolvedBackgroundColor,
                Services.ThemeService.theme.tokens.primary)
                || !Qt.colorEqual(button.resolvedForegroundColor,
                    Services.ThemeService.theme.tokens.on_primary))
            return fail("pending button does not retain primary emphasis");

        button.pending = false;
        button.enabled = true;
        button.focus = false;
        button.tone = "destructive";
        if (!Qt.colorEqual(button.resolvedForegroundColor,
                Services.ThemeService.theme.tokens.on_surface)
                || !Qt.colorEqual(button.resolvedBorderColor,
                    Services.ThemeService.theme.tokens.error))
            return fail("destructive button does not use error accents");

        button.tone = "primary";
        if (!Qt.colorEqual(button.resolvedForegroundColor,
                Services.ThemeService.theme.tokens.on_surface)
                || !Qt.colorEqual(button.resolvedBorderColor,
                    Services.ThemeService.theme.tokens.primary))
            return fail(`outlined primary colors are ${button.resolvedForegroundColor}/${button.resolvedBorderColor}`);

        button.emphasis = "ghost";
        if (button.resolvedBorderWidth !== 0
                || !Qt.colorEqual(button.resolvedForegroundColor,
                    Services.ThemeService.theme.tokens.primary))
            return fail("ghost button retains an outlined border");

        button.emphasis = "filled";
        if (!Qt.colorEqual(button.resolvedBackgroundColor,
                Services.ThemeService.theme.tokens.primary)
                || !Qt.colorEqual(button.resolvedForegroundColor,
                    Services.ThemeService.theme.tokens.on_primary))
            return fail("filled primary button does not use the primary pair");

        console.log("ACTION_BUTTON_TEST_PASSED");
        Qt.quit();
    }

    FloatingWindow {
        visible: true
        implicitWidth: 240
        implicitHeight: 80

        Components.ActionButton {
            id: button
            anchors.centerIn: parent
            text: "Action"
        }

        Components.IconButton {
            id: iconButton
            width: 52
            height: 52
            iconName: "palette"
        }

        Components.ActionButton {
            id: groupedButton
            x: 80
            width: 140
            iconName: "save"
            text: "Save"
        }
    }

    Timer { interval: 50; running: true; onTriggered: root.check() }
    Timer { interval: 5000; running: true; onTriggered: root.fail("test timed out") }
}
