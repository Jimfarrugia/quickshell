import Quickshell
import Quickshell.Io
import "../services" as Services

Scope {
    id: root

    function open(): void { Services.SurfaceService.openThemeSelector(); }
    function close(): void { Services.SurfaceService.closeThemeSelector(); }
    function toggle(): void { Services.SurfaceService.toggleThemeSelector(); }
    function isOpen(): bool { return Services.SurfaceService.themeSelectorVisible; }

    IpcHandler {
        target: "qe-theme"

        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function toggle(): void { root.toggle(); }
        function isOpen(): bool { return root.isOpen(); }
    }
}
