pragma Singleton

import Quickshell

Singleton {
    readonly property string shellDirectory: Quickshell.shellDir
    readonly property string configFile: Quickshell.shellPath("config/qe.json")
    readonly property string themeDirectory: Quickshell.shellPath("themes")
    readonly property string activeThemeState: Quickshell.statePath("active-theme.json")
    readonly property string wallpaperState: Quickshell.statePath("wallpaper.json")
    readonly property string generatedThemePath: Quickshell.dataPath("Wallpaper.json")
    readonly property string wallpaperRoot: Quickshell.env("QE_WALLPAPER_ROOT")
        || `${Quickshell.env("HOME")}/Pictures/Wallpaper`
    readonly property string dataDirectory: Quickshell.dataDir
    readonly property string stateDirectory: Quickshell.stateDir
    readonly property string cacheDirectory: Quickshell.cacheDir

    function shellPath(relativePath) { return Quickshell.shellPath(relativePath); }
    function dataPath(relativePath) { return Quickshell.dataPath(relativePath); }
    function statePath(relativePath) { return Quickshell.statePath(relativePath); }
    function cachePath(relativePath) { return Quickshell.cachePath(relativePath); }
}
