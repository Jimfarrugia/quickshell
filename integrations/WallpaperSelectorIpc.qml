import Quickshell
import Quickshell.Io
import "../services" as Services

Scope {
    id: root

    function open(): void { Services.SurfaceService.openWallpaperSelector(); }
    function close(): void { Services.SurfaceService.closeWallpaperSelector(); }
    function toggle(): void { Services.SurfaceService.toggleWallpaperSelector(); }
    function isOpen(): bool { return Services.SurfaceService.wallpaperSelectorVisible; }

    IpcHandler {
        target: "qe-wallpaper"

        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function toggle(): void { root.toggle(); }
        function isOpen(): bool { return root.isOpen(); }
    }
}
