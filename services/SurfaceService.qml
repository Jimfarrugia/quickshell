pragma Singleton

import Quickshell

Singleton {
    property bool themeSelectorVisible: false
    property bool wallpaperSelectorVisible: false

    function openThemeSelector() { themeSelectorVisible = true; }
    function closeThemeSelector() { themeSelectorVisible = false; }
    function toggleThemeSelector() { themeSelectorVisible = !themeSelectorVisible; }
    function openWallpaperSelector() { wallpaperSelectorVisible = true; }
    function closeWallpaperSelector() { wallpaperSelectorVisible = false; }
    function toggleWallpaperSelector() { wallpaperSelectorVisible = !wallpaperSelectorVisible; }
}
