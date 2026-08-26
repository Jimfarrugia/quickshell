import QtQuick
import QtQml
import Quickshell
import Quickshell.Io
import "integrations"
import "services" as Services

ShellRoot {
    id: root

    property bool started: false
    readonly property string imagePath: Quickshell.env("QE_TEST_WALLPAPER")
        || `${Services.WallpaperService.wallpaperRoot}/themes/poimandres/sample.png`
    readonly property var expectedIds: ["bat","btop","dunst","eza","fzf","hyprland","hyprlock","kitty","nvim","opencode","rofi","starship","tmux"]

    Scope {
        id: fakeExternal
        property string availability: "available"
        readonly property bool running: false
        property string capturedSpec: ""
        property string capturedOperationId: ""
        property var capturedTargets: []

        signal finished(var result)

        function apply(specPath, operationId) {
            capturedSpec = specPath;
            capturedOperationId = operationId;
            specView.path = specPath;
            return true;
        }

        FileView {
            id: specView
            blockLoading: true
            printErrors: false
            onLoaded: {
                let parsed = null;
                try { parsed = JSON.parse(specView.text()); } catch (error) { fakeExternal.onVerifiedResult({ ok: false }); return; }
                fakeExternal.capturedTargets = parsed.targets;
                fakeExternal.onVerifiedResult({ ok: true });
            }
            onLoadFailed: fakeExternal.onVerifiedResult({ ok: false })
        }

        function onVerifiedResult(check) {
            const status = check.ok ? "succeeded" : "failed";
            const results = check.ok ? capturedTargets.map(target => ({ id: target.id, status: "applied" })) : [];
            finished({
                operationId: capturedOperationId,
                contractValid: check.ok,
                success: check.ok,
                status,
                results,
                failedTargets: check.ok ? [] : [],
                skippedTargets: 0,
                error: check.ok ? "" : "spec verification failed"
            });
        }
    }

    MatugenAdapter {
        id: matugenAdapter
        executable: Quickshell.env("QE_MATUGEN")
    }

    WallpaperPromotionAdapter {
        id: promotionAdapter
    }

    Binding {
        target: Services.WallpaperService
        property: "matugenAdapter"
        value: matugenAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: Services.WallpaperService
        property: "promotionAdapter"
        value: promotionAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: Services.WallpaperService
        property: "externalThemeAdapter"
        value: fakeExternal
        restoreMode: Binding.RestoreBindingOrValue
    }

    function begin() {
        if (started || !Services.WallpaperService.initialized
                || matugenAdapter.availability !== "available") return;
        started = true;
        if (!Services.WallpaperService.requestGeneration(root.imagePath))
            fail("wallpaper service rejected a valid generation request");
    }

    function fail(message) {
        console.error(`EXTERNAL_WALLPAPER_THEME_TEST_FAILED: ${message}`);
        Qt.quit();
    }

    function verifyTargets() {
        const home = Quickshell.env("HOME");
        const cacheHome = Quickshell.env("XDG_CACHE_HOME") || `${home}/.cache`;
        const targets = fakeExternal.capturedTargets;
        if (!Array.isArray(targets) || targets.length !== expectedIds.length)
            return `expected ${expectedIds.length} targets, got ${Array.isArray(targets) ? targets.length : "none"}`;
        const ids = targets.map(target => target.id).sort().join(",");
        if (ids !== [...expectedIds].sort().join(","))
            return `target ids mismatch: ${ids}`;
        for (const target of targets) {
            if (!target.path.startsWith("/") || target.path.includes(".."))
                return `invalid target path: ${target.path}`;
            if (!(typeof target.content === "string") || target.content.length === 0)
                return `empty content for ${target.id}`;
            if (target.id === "nvim" && !target.path.startsWith(`${cacheHome}/matugen/`))
                return `nvim palette path unexpected: ${target.path}`;
            if (target.id === "fzf" && !target.path.startsWith(`${home}/.config/zsh/`))
                return `fzf theme path unexpected: ${target.path}`;
        }
        return null;
    }

    Connections {
        target: matugenAdapter
        function onAvailabilityChanged() { root.begin(); }
    }

    Connections {
        target: Services.WallpaperService
        function onInitializedChanged() { root.begin(); }
        function onGenerationStatusChanged() {
            if (Services.WallpaperService.generationStatus === "failed")
                root.fail(Services.WallpaperService.lastError);
        }
        function onExternalThemeStatusChanged() {
            const status = Services.WallpaperService.externalThemeStatus;
            if (status === "failed")
                root.fail(Services.WallpaperService.lastError);
            if (status === "succeeded") {
                const error = root.verifyTargets();
                if (error) return root.fail(error);
                console.log("EXTERNAL_WALLPAPER_THEME_TEST_PASSED");
                Qt.quit();
            }
        }
    }

    Timer {
        interval: 120000
        running: true
        onTriggered: root.fail("external wallpaper theme test timed out")
    }

    Component.onCompleted: root.begin()
}
