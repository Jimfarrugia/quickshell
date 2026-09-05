import QtQuick
import Quickshell
import "services" as Services

ShellRoot {
    id: root

    property int restarts: 0

    QtObject {
        id: fakeAdapter
        property bool running: false
        property string lastAction: ""
        property real lastPrimaryScale: 0
        property real lastSecondaryScale: 0
        function start(action, mode, direction, primaryScale, secondaryScale) {
            lastAction = action;
            lastPrimaryScale = primaryScale;
            lastSecondaryScale = secondaryScale;
            return true;
        }
    }

    QtObject {
        id: fakeLifecycle
        property string restartError: ""
        property bool shouldFail: false
        function restart() {
            root.restarts++;
            if (shouldFail) restartError = "Injected restart failure";
            return !shouldFail;
        }
    }

    function result(mode, direction, restartRequired, primaryScale, secondaryScale) {
        const primary = primaryScale === undefined ? 1.25 : primaryScale;
        const secondary = secondaryScale === undefined ? 1.5 : secondaryScale;
        return {
            success: true,
            parsed: {
                version: 2,
                available: true,
                message: "",
                mode,
                direction,
                primaryScale: mode === "unknown" ? null : primary,
                secondaryScale: mode === "unknown" ? null : secondary,
                selectedMode: mode,
                selectedDirection: direction === "unknown" ? "up" : direction,
                selectedPrimaryScale: primary,
                selectedSecondaryScale: secondary,
                secondaryConnected: true,
                restartRequired,
                stateValid: true,
                migrationNeeded: false,
                stateMatchesLive: true
            },
            stderr: "",
            parseError: null,
            timedOut: false
        };
    }

    function fail(message) {
        console.error(`MONITOR_LAYOUT_SERVICE_TEST_FAILED: ${message}`);
        Qt.exit(1);
    }

    Component.onCompleted: {
        Services.MonitorLayoutService.adapter = fakeAdapter;
        Services.MonitorLayoutService.lifecycleService = fakeLifecycle;
        const drift = result("extended", "up", false, 1.5, 2);
        drift.parsed.selectedPrimaryScale = 1.25;
        drift.parsed.selectedSecondaryScale = 1.5;
        drift.parsed.stateMatchesLive = false;
        drift.parsed.message = "Live monitor settings differ from the saved profile";
        Services.MonitorLayoutService.complete("query", drift);
        if (Services.MonitorLayoutService.availability !== "degraded"
                || Services.MonitorLayoutService.confirmedPrimaryScale !== 1.5
                || Services.MonitorLayoutService.selectedPrimaryScale !== 1.25)
            return fail("live scale drift was not kept separate from saved state");
        const unavailable = result("unknown", "unknown", false);
        unavailable.parsed.available = false;
        unavailable.parsed.selectedMode = "mirror";
        unavailable.parsed.selectedDirection = "down";
        Services.MonitorLayoutService.complete("query", unavailable);
        if (Services.MonitorLayoutService.confirmedMode !== ""
                || Services.MonitorLayoutService.confirmedDirection !== ""
                || Services.MonitorLayoutService.selectedMode !== "mirror"
                || Services.MonitorLayoutService.selectedDirection !== "down"
                || Services.MonitorLayoutService.confirmedPrimaryScale !== 0)
            return fail("unavailable live state was presented as confirmed");
        Services.MonitorLayoutService.complete("query", result("mirror", "unknown", false));
        if (Services.MonitorLayoutService.availability !== "available"
                || Services.MonitorLayoutService.confirmedMode !== "mirror"
                || Services.MonitorLayoutService.confirmedDirection !== "")
            return fail("query result was not published");
        if (!Services.MonitorLayoutService.requestMode("extended")
                || Services.MonitorLayoutService.operation !== "pending")
            return fail("extended request did not enter pending state");
        Services.MonitorLayoutService.complete("apply", result("extended", "left", true));
        Qt.callLater(() => {
            if (Services.MonitorLayoutService.confirmedMode !== "extended"
                    || Services.MonitorLayoutService.confirmedDirection !== "left"
                    || Services.MonitorLayoutService.selectedMode !== "extended"
                    || Services.MonitorLayoutService.selectedDirection !== "left"
                    || Services.MonitorLayoutService.confirmedPrimaryScale !== 1.25
                    || Services.MonitorLayoutService.confirmedSecondaryScale !== 1.5)
                return fail("confirmed extended layout was not published");
            if (root.restarts !== 1)
                return fail("mirror-to-extended transition did not restart QE");
            if (Services.MonitorLayoutService.requestPrimaryScale(1.4)
                    || Services.MonitorLayoutService.operation === "pending")
                return fail("service accepted an invalid scale");
            if (!Services.MonitorLayoutService.requestPrimaryScale(1.6)
                    || fakeAdapter.lastPrimaryScale !== 1.6
                    || fakeAdapter.lastSecondaryScale !== 1.5)
                return fail("primary scale request was not forwarded independently");
            Services.MonitorLayoutService.complete("apply",
                result("extended", "left", false, 1.6, 1.5));
            if (Services.MonitorLayoutService.confirmedPrimaryScale !== 1.6
                    || Services.MonitorLayoutService.confirmedSecondaryScale !== 1.5)
                return fail("confirmed independent scales were not published");
            fakeLifecycle.shouldFail = true;
            Services.MonitorLayoutService.complete("apply", result("extended", "right", true));
            Qt.callLater(() => {
                if (Services.MonitorLayoutService.operation !== "failed"
                        || Services.MonitorLayoutService.operationError !== "Injected restart failure")
                    return fail("restart failure was not exposed");
                console.log("MONITOR_LAYOUT_SERVICE_TEST_PASSED");
                Qt.quit();
            });
        });
    }
}
