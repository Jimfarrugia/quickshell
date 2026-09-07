import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string statePath: Quickshell.statePath("wallpaper.json")
    property string wallpaperRoot: Quickshell.env("QE_WALLPAPER_ROOT")
        || `${Quickshell.env("HOME")}/Pictures/Wallpaper`
    property string defaultWallpaperPath: Quickshell.shellPath("defaults/wallpaper/images/current-wallpaper.png")
    property int loadTimeoutMs: 1500
    property int maxInputCharacters: 262144
    property int maxImageWidth: 3840
    property int maxImageHeight: 2160
    property bool ready: false
    property bool usingFallback: true
    property string sourceUrl: ""
    property var errors: []
    readonly property bool watchersActive: !frozen
    property bool frozen: false
    property bool settling: false
    property string sourcePath: ""
    property string pendingReason: ""

    width: 0
    height: 0
    visible: false

    function urlForPath(path) {
        return `file://${path.split("/").map(part => encodeURIComponent(part)).join("/")}`;
    }

    function validPath(path) {
        if (typeof path !== "string" || !/^\/(?:[^/]+\/)*[^/]+$/.test(path)) return false;
        const normalizedRoot = wallpaperRoot.replace(/\/+$/, "");
        return path === defaultWallpaperPath
            || (path.startsWith(`${normalizedRoot}/`) && !path.split("/").includes(".."));
    }

    function settle(source, reason) {
        if (ready) return;
        frozen = true;
        settling = false;
        loadTimer.stop();
        if (source !== "") {
            sourceUrl = urlForPath(source);
            usingFallback = false;
        } else {
            sourceUrl = "";
            usingFallback = true;
        }
        if (reason) errors = [reason];
        stateFile.path = "";
        ready = true;
    }

    function inspectState() {
        if (ready) return;
        if (!stateFile.loaded) {
            loadImage(defaultWallpaperPath, "wallpaper state unavailable; using authored default");
            return;
        }
        const text = stateFile.text();
        if (text.length > maxInputCharacters) {
            settle("", "wallpaper state is too large");
            return;
        }
        let parsed;
        try {
            parsed = JSON.parse(text);
        } catch (error) {
            settle("", `invalid wallpaper state: ${error.message}`);
            return;
        }
        if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)
                || parsed.schemaVersion !== 1 || !validPath(parsed.selectedPath)) {
            settle("", "wallpaper state path is outside the configured root or malformed");
            return;
        }
        sourcePath = parsed.selectedPath;
        loadImage(sourcePath, "");
    }

    function loadImage(path, reason) {
        if (ready) return;
        sourcePath = path;
        pendingReason = reason;
        settling = true;
        candidate.source = urlForPath(sourcePath);
        loadTimer.restart();
    }

    Image {
        id: candidate
        sourceSize: Qt.size(root.maxImageWidth, root.maxImageHeight)
        asynchronous: true
        cache: true
        onStatusChanged: {
            if (status === Image.Ready)
                root.settle(root.sourcePath, root.pendingReason);
            else if (status === Image.Error)
                root.settle("", "wallpaper image could not be decoded");
        }
    }

    FileView {
        id: stateFile
        path: root.statePath
        blockLoading: true
        watchChanges: false
        printErrors: false
        onLoaded: root.inspectState()
        onLoadFailed: root.inspectState()
    }

    Timer {
        id: loadTimer
        interval: root.loadTimeoutMs
        repeat: false
        onTriggered: root.settle("", "wallpaper image loading timed out")
    }
}
