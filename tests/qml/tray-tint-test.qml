import QtQuick
import Quickshell
import "modules/bar" as Bar
import "services" as Services

ShellRoot {
    id: root

    QtObject {
        id: nextcloud
        property string title: "Nextcloud"
        property string icon: "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==#synced"
    }

    QtObject {
        id: other
        property string title: "Other"
        property string icon: "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==#other"
    }

    Bar.TrayHost {
        id: tray
        items: [nextcloud, other]
    }

    function fail(message) {
        console.error(`TRAY_TINT_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function runChecks() {
        const nextcloudDelegate = tray.itemAt(0);
        const otherDelegate = tray.itemAt(1);
        if (!nextcloudDelegate || !otherDelegate)
            return fail("tray delegates were not created");
        if (!nextcloudDelegate.themedIcon || !otherDelegate.themedIcon)
            return fail("not every tray icon used the color-overlay path");
        if (nextcloudDelegate.tintColor.toString() !== Services.ThemeService.theme.tokens.secondary.toString()
                || otherDelegate.tintColor.toString() !== Services.ThemeService.theme.tokens.secondary.toString())
            return fail("tray icons did not use the default bar icon color");
        if (nextcloudDelegate.iconSource !== nextcloud.icon)
            return fail("color-overlay path did not retain the native dynamic icon source");
        if (otherDelegate.iconSource !== other.icon)
            return fail("second tray icon did not retain its native icon source");
        if (tray.hoverBackground(true).toString() !== Services.ThemeService.theme.tokens.surface_hover.toString()
                || nextcloudDelegate.radius !== 7)
            return fail("tray hover styling does not match BarChip");

        nextcloud.icon = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==#syncing";
        other.icon = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==#updated";
        Qt.callLater(checkReactiveSource);
    }

    function checkReactiveSource() {
        if (tray.itemAt(0).iconSource !== nextcloud.icon)
            return fail("first native icon update did not remain reactive");
        if (tray.itemAt(1).iconSource !== other.icon)
            return fail("second native icon update did not remain reactive");
        console.log("TRAY_TINT_TEST_PASSED");
        Qt.quit();
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: root.fail("test timed out")
    }

    Component.onCompleted: Qt.callLater(runChecks)
}
