pragma Singleton

import Quickshell

Singleton {
    property bool themeSelectorVisible: false
    property bool wallpaperSelectorVisible: false
    property bool paletteViewerVisible: false
    property bool notificationCenterVisible: false
    property bool launcherVisible: false
    property bool helpVisible: false
    property var dashboardController: null

    function openThemeSelector() { themeSelectorVisible = true; }
    function closeThemeSelector() { themeSelectorVisible = false; }
    function toggleThemeSelector() { themeSelectorVisible = !themeSelectorVisible; }
    function openWallpaperSelector() { wallpaperSelectorVisible = true; }
    function closeWallpaperSelector() { wallpaperSelectorVisible = false; }
    function toggleWallpaperSelector() { wallpaperSelectorVisible = !wallpaperSelectorVisible; }
    function openPaletteViewer() { paletteViewerVisible = true; }
    function closePaletteViewer() { paletteViewerVisible = false; }
    function togglePaletteViewer() { paletteViewerVisible = !paletteViewerVisible; }
    function openNotificationCenter() { notificationCenterVisible = true; }
    function closeNotificationCenter() { notificationCenterVisible = false; }
    function toggleNotificationCenter() { notificationCenterVisible = !notificationCenterVisible; }
    function openLauncher() { launcherVisible = true; }
    function closeLauncher() { launcherVisible = false; }
    function toggleLauncher() { launcherVisible ? closeLauncher() : openLauncher(); }
    function openHelp() { helpVisible = true; }
    function closeHelp() { helpVisible = false; }
    function toggleHelp() { helpVisible ? closeHelp() : openHelp(); }
    function activeScreen() {
        const focusedName = CompositorService.focusedMonitorName;
        return Quickshell.screens.find(screen => screen.name === focusedName)
            || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
    }
    function toggleDashboard(id, screen, side) {
        if (dashboardController) dashboardController.toggle(id, screen, side);
    }
}
