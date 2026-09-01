pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../utils/Help.mjs" as Help

Singleton {
    id: root
    property string query: ""
    property var entries: []
    property var results: []
    property string warning: ""
    property bool userLoaded: false
    property bool warningReported: false
    property bool userAttempted: false
    property bool pendingOpen: false
    property var userEntries: []

    function parseCatalog(file, boundary) {
        try {
            return Help.validateCatalog(JSON.parse(file.text()), boundary);
        } catch (error) {
            return { entries: [], errors: [`${boundary}: invalid JSON`] };
        }
    }

    function rebuild() {
        if (userLoaded) {
            const user = parseCatalog(userFile, "config/help");
            userEntries = user.entries;
            if (user.errors.length) setWarning(user.errors.join("; "));
        }
        entries = userEntries;
        results = Help.search(entries, query);
        maybeOpen();
    }
    function maybeOpen() {
        if (pendingOpen && userAttempted) {
            pendingOpen = false;
            SurfaceService.openHelp();
        }
    }
    function setWarning(message) {
        warning = message;
        if (!warningReported) {
            warningReported = true;
            DiagnosticsService.report("HELP_CATALOG_REJECTED", "help", "Help catalog issue", message, false, null);
        }
    }
    function refresh() {
        query = "";
        warning = "";
        warningReported = false;
        pendingOpen = true;
        userAttempted = false;
        userLoaded = false;
        userFile.reload();
    }
    function setQuery(value) {
        query = value;
        results = Help.search(entries, query);
    }
    function close() { SurfaceService.closeHelp(); }

    FileView {
        id: userFile
        path: PathsService.helpCatalog
        blockLoading: true
        watchChanges: false
        printErrors: false
        onLoaded: { root.userLoaded = true; root.userAttempted = true; root.rebuild(); }
        onLoadFailed: { root.userLoaded = false; root.userAttempted = true; root.setWarning("User help catalog is unavailable"); root.rebuild(); }
    }
    Component.onCompleted: userFile.reload()
}
