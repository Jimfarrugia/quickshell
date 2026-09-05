pragma Singleton

import Quickshell

Singleton {
    property bool themeSelectorVisible: false
    property bool wallpaperSelectorVisible: false
    property bool paletteViewerVisible: false
    property bool notificationCenterVisible: false
    property bool launcherVisible: false
    property bool helpVisible: false
    property bool controlCenterVisible: false
    property var dashboardController: null

    function openThemeSelector() { closeControlCenter(); themeSelectorVisible = true; }
    function closeThemeSelector() { themeSelectorVisible = false; }
    function toggleThemeSelector() { themeSelectorVisible ? closeThemeSelector() : openThemeSelector(); }
    function openWallpaperSelector() { closeControlCenter(); wallpaperSelectorVisible = true; }
    function closeWallpaperSelector() { wallpaperSelectorVisible = false; }
    function toggleWallpaperSelector() { wallpaperSelectorVisible ? closeWallpaperSelector() : openWallpaperSelector(); }
    function openPaletteViewer() { closeControlCenter(); paletteViewerVisible = true; }
    function closePaletteViewer() { paletteViewerVisible = false; }
    function togglePaletteViewer() { paletteViewerVisible ? closePaletteViewer() : openPaletteViewer(); }
    function openNotificationCenter() { closeControlCenter(); notificationCenterVisible = true; }
    function closeNotificationCenter() { notificationCenterVisible = false; }
    function toggleNotificationCenter() { notificationCenterVisible ? closeNotificationCenter() : openNotificationCenter(); }
    function openLauncher() { closeControlCenter(); launcherVisible = true; }
    function closeLauncher() { launcherVisible = false; }
    function toggleLauncher() { launcherVisible ? closeLauncher() : openLauncher(); }
    function openHelp() { closeControlCenter(); helpVisible = true; }
    function closeHelp() { helpVisible = false; }
    function toggleHelp() { helpVisible ? closeHelp() : openHelp(); }
    function openControlCenter() {
        closeTransientSurfaces();
        controlCenterVisible = true;
    }
    function closeControlCenter() {
        controlCenterVisible = false;
    }
    function toggleControlCenter() {
        controlCenterVisible ? closeControlCenter() : openControlCenter();
    }
    function closeTransientSurfaces() {
        themeSelectorVisible = false;
        wallpaperSelectorVisible = false;
        paletteViewerVisible = false;
        notificationCenterVisible = false;
        launcherVisible = false;
        helpVisible = false;
        if (dashboardController) dashboardController.close();
    }
    function openDashboard(id, screen, side) {
        closeControlCenter();
        if (dashboardController) dashboardController.open(id, screen || null, side || "right");
    }
    function activeScreen() {
        const focusedName = CompositorService.focusedMonitorName;
        return Quickshell.screens.find(screen => screen.name === focusedName)
            || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
    }
    function toggleDashboard(id, screen, side) {
        if (!dashboardController) return;
        if (dashboardController.isOpen(id)) dashboardController.close();
        else openDashboard(id, screen, side);
    }

}
