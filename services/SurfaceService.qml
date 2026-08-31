pragma Singleton

import Quickshell

Singleton {
    property bool themeSelectorVisible: false
    property bool wallpaperSelectorVisible: false
    property bool paletteViewerVisible: false
    property bool notificationCenterVisible: false
    property bool launcherVisible: false

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
}
