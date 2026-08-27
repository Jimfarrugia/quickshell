import Quickshell
import Quickshell.Io
import "../services" as Services

Scope {
    id: root

    function open(): void { Services.SurfaceService.openWallpaperSelector(); }
    function close(): void { Services.SurfaceService.closeWallpaperSelector(); }
    function toggle(): void { Services.SurfaceService.toggleWallpaperSelector(); }
    function isOpen(): bool { return Services.SurfaceService.wallpaperSelectorVisible; }
    function operation(): string { return Services.WallpaperService.operation; }
    function generationStatus(): string { return Services.WallpaperService.generationStatus; }
    function externalThemeStatus(): string { return Services.WallpaperService.externalThemeStatus; }
    function applyDefault(): bool { return Services.WallpaperService.requestDefaultWallpaper(); }

    IpcHandler {
        target: "qe-wallpaper"

        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function toggle(): void { root.toggle(); }
        function isOpen(): bool { return root.isOpen(); }
        function operation(): string { return root.operation(); }
        function generationStatus(): string { return root.generationStatus(); }
        function externalThemeStatus(): string { return root.externalThemeStatus(); }
        function applyDefault(): bool { return root.applyDefault(); }
    }
}
