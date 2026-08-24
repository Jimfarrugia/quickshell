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
        if (!nextcloudDelegate.themedIcon
                || nextcloudDelegate.tintColor.toString() !== Services.ThemeService.theme.tokens.accentSecondary.toString())
            return fail("Nextcloud did not use the accentSecondary tint path");
        if (nextcloudDelegate.iconSource !== nextcloud.icon)
            return fail("Nextcloud tint path did not retain the native dynamic icon source");
        if (otherDelegate.themedIcon || otherDelegate.iconSource !== other.icon)
            return fail("non-Nextcloud tray icon was modified");

        nextcloud.icon = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==#syncing";
        Qt.callLater(checkReactiveSource);
    }

    function checkReactiveSource() {
        if (tray.itemAt(0).iconSource !== nextcloud.icon)
            return fail("Nextcloud native icon update did not remain reactive");
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
