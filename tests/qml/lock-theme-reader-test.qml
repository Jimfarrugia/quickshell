import QtQuick
import Quickshell
import "lock" as Lock

ShellRoot {
    id: root

    Lock.LockThemeReader {
        id: validReader
        configPath: Quickshell.shellPath("config/qe.json")
        activeThemeStatePath: Quickshell.shellPath("fixtures/lock/active-theme.json")
        themeDirectory: Quickshell.shellPath("themes")
        generatedThemePath: Quickshell.shellPath("fixtures/lock/missing-generated-theme.json")
    }

    Lock.LockThemeReader {
        id: fallbackReader
        configPath: Quickshell.shellPath("config/qe.json")
        activeThemeStatePath: Quickshell.shellPath("fixtures/lock/invalid-active-theme.json")
        themeDirectory: Quickshell.shellPath("themes")
        generatedThemePath: Quickshell.shellPath("fixtures/lock/missing-generated-theme.json")
    }

    Lock.LockThemeReader {
        id: invalidConfigReader
        configPath: Quickshell.shellPath("fixtures/lock/partial-config.json")
        activeThemeStatePath: Quickshell.shellPath("fixtures/lock/active-theme.json")
        themeDirectory: Quickshell.shellPath("themes")
        generatedThemePath: Quickshell.shellPath("fixtures/lock/missing-generated-theme.json")
    }

    Lock.LockThemeReader {
        id: malformedThemeReader
        configPath: Quickshell.shellPath("config/qe.json")
        activeThemeStatePath: Quickshell.shellPath("fixtures/lock/broken-theme-state.json")
        themeDirectory: Quickshell.shellPath("fixtures/lock/themes")
        generatedThemePath: Quickshell.shellPath("fixtures/lock/missing-generated-theme.json")
    }

    Lock.LockThemeReader {
        id: oversizedReader
        configPath: Quickshell.shellPath("config/qe.json")
        activeThemeStatePath: Quickshell.shellPath("fixtures/lock/active-theme.json")
        themeDirectory: Quickshell.shellPath("themes")
        generatedThemePath: Quickshell.shellPath("fixtures/lock/missing-generated-theme.json")
        maxInputCharacters: 32
    }

    Lock.LockThemeReader {
        id: timeoutReader
        configPath: Quickshell.shellPath("config/qe.json")
        activeThemeStatePath: Quickshell.shellPath("fixtures/lock/active-theme.json")
        themeDirectory: Quickshell.shellPath("fixtures/lock/missing-theme-directory")
        generatedThemePath: Quickshell.shellPath("fixtures/lock/missing-generated-theme.json")
        loadTimeoutMs: 0
    }

    function fail(message) {
        console.error(`LOCK_THEME_READER_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function check() {
        if (!validReader.ready || !fallbackReader.ready || !invalidConfigReader.ready
                || !malformedThemeReader.ready || !oversizedReader.ready
                || !timeoutReader.ready)
            return;
        if (validReader.usingFallback || validReader.theme.id !== "poimandres"
                || validReader.theme.tokens.background.toLowerCase() !== "#1b1e28")
            return fail("validated active theme was not published");
        if (fallbackReader.appearance.fontFamily.length === 0)
            return fail("validated lock-safe appearance was not published");
        if (!fallbackReader.usingFallback || fallbackReader.theme.id !== "lock_emergency"
                || fallbackReader.theme.tokens.background !== "#000000")
            return fail("invalid active state did not use the opaque lock fallback");
        if (validReader.watchersActive || fallbackReader.watchersActive)
            return fail("lock reader retained file watchers after initialization");
        if (invalidConfigReader.appearance.fontFamily !== "Inter"
                || invalidConfigReader.appearance.radius !== 10
                || invalidConfigReader.errors.length === 0)
            return fail("invalid config fields were partially published instead of whole-document fallback");
        if (!malformedThemeReader.usingFallback
                || !malformedThemeReader.errors.some(error => error.includes("invalid JSON")))
            return fail("malformed active theme did not use the lock fallback");
        if (!oversizedReader.usingFallback
                || !oversizedReader.errors.some(error => error.includes("too large")))
            return fail("oversized lock input was not rejected");
        if (!timeoutReader.usingFallback
                || !timeoutReader.errors.some(error => error.includes("timed out")))
            return fail("unsettled lock input did not fall back by the deadline");
        if (invalidConfigReader.watchersActive || malformedThemeReader.watchersActive
                || oversizedReader.watchersActive || timeoutReader.watchersActive)
            return fail(`failure-path reader retained discovery watchers: invalidConfig=${invalidConfigReader.watchersActive}, malformedTheme=${malformedThemeReader.watchersActive}, oversized=${oversizedReader.watchersActive}, timeout=${timeoutReader.watchersActive}`);
        console.log("LOCK_THEME_READER_TEST_PASSED");
        Qt.quit();
    }

    Connections {
        target: validReader
        function onReadyChanged() { root.check(); }
    }

    Connections {
        target: fallbackReader
        function onReadyChanged() { root.check(); }
    }

    Connections {
        target: invalidConfigReader
        function onReadyChanged() { root.check(); }
    }

    Connections {
        target: malformedThemeReader
        function onReadyChanged() { root.check(); }
    }

    Connections {
        target: oversizedReader
        function onReadyChanged() { root.check(); }
    }

    Connections {
        target: timeoutReader
        function onReadyChanged() { root.check(); }
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: root.fail(`test timed out: valid=${validReader.ready}/${validReader.watchersActive}, fallback=${fallbackReader.ready}/${fallbackReader.watchersActive}, invalidConfig=${invalidConfigReader.ready}/${invalidConfigReader.watchersActive}, malformedTheme=${malformedThemeReader.ready}/${malformedThemeReader.watchersActive}, oversized=${oversizedReader.ready}/${oversizedReader.watchersActive}, timeout=${timeoutReader.ready}/${timeoutReader.watchersActive}/${timeoutReader.themeFolder.count}/${timeoutReader.themeFiles.count}/${timeoutReader.frozen}/${timeoutReader.deactivating}`)
    }

    Component.onCompleted: check()
}
