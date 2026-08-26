import QtQuick
import QtQml
import Quickshell
import "services" as Services

ShellRoot {
    id: root

    property bool requested: false
    property string expectedThemeId: ""

    function begin() {
        if (requested || !Services.ThemeService.initialized || Services.ThemeService.catalog.length < 2)
            return;
        expectedThemeId = Services.ThemeService.activeThemeId === "poimandres" ? "gruvbox" : "poimandres";
        requested = true;
        if (!Services.ThemeService.requestTheme(expectedThemeId))
            fail("valid QE theme request was rejected");
    }

    function fail(message) {
        console.error(`EXTERNAL_THEME_SERVICE_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    QtObject {
        id: fakeAdapter
        property string availability: "available"
        property var lastState: null
        property bool called: false
        property bool concurrentRejected: false
        property string capturedThemeId: ""
        property string capturedOperationId: ""
        signal finished(var result)

        function start(themeId, operationId) {
            called = true;
            capturedThemeId = themeId;
            capturedOperationId = operationId;
            const otherThemeId = themeId === "poimandres" ? "gruvbox" : "poimandres";
            concurrentRejected = !Services.ThemeService.requestTheme(otherThemeId);
            Qt.callLater(() => finished({
                operationId,
                contractValid: true,
                status: "partial",
                persisted: true,
                requestedThemeId: themeId,
                targets: [
                    { target: "gtk", status: "applied", exitCode: 0, reason: null, detail: null },
                    { target: "nvim", status: "failed", exitCode: 1, reason: null, detail: "fixture failure" }
                ],
                error: null,
                timedOut: false,
                stderr: ""
            }));
            return true;
        }
    }

    Binding {
        target: Services.ThemeService
        property: "externalAdapter"
        value: fakeAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }

    Connections {
        target: Services.ThemeService
        function onInitializedChanged() { root.begin(); }
        function onCatalogChanged() { root.begin(); }
        function onExternalOperationChanged() {
            if (Services.ThemeService.externalOperation !== "succeeded") return;
            if (!fakeAdapter.called || fakeAdapter.capturedThemeId !== root.expectedThemeId)
                return root.fail("external adapter did not receive the committed QE theme");
            if (!fakeAdapter.concurrentRejected)
                return root.fail("concurrent theme request was not serialized through the external phase");
            if (Services.ThemeService.activeThemeId !== root.expectedThemeId)
                return root.fail("external partial failure rolled back the QE theme");
            if (Services.ThemeService.externalStatus !== "partial"
                    || Services.ThemeService.externalResults.length !== 2)
                return root.fail("external partial result was not published truthfully");
            console.log("EXTERNAL_THEME_SERVICE_TEST_PASSED");
            Qt.quit();
        }
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail("external theme service test timed out")
    }

    Component.onCompleted: begin()
}
