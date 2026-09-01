pragma Singleton

import Quickshell

Singleton {
    readonly property string shellDirectory: Quickshell.shellDir
    readonly property string configFile: Quickshell.shellPath("config/qe.json")
    readonly property string helpCatalog: Quickshell.shellPath("config/help.json")
    readonly property string defaultsManifest: Quickshell.shellPath("defaults/manifest.json")
    readonly property string defaultWallpaperImage: Quickshell.shellPath("defaults/wallpaper/images/current-wallpaper.png")
    readonly property string themeDirectory: Quickshell.shellPath("themes")
    readonly property string activeThemeState: Quickshell.statePath("active-theme.json")
    readonly property string wallpaperState: Quickshell.statePath("wallpaper.json")
    readonly property string notificationState: Quickshell.statePath("notifications.json")
    readonly property string launcherUsageState: Quickshell.statePath("launcher-usage.json")
    readonly property string dataHome: Quickshell.env("XDG_DATA_HOME")
        || `${Quickshell.env("HOME")}/.local/share`
    readonly property string generatedThemePath: `${dataHome}/qe/wallpaper/Wallpaper.json`
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
