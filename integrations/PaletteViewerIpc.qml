import Quickshell
import Quickshell.Io
import "../services" as Services

Scope {
    id: root

    function open(): void { Services.SurfaceService.openPaletteViewer(); }
    function close(): void { Services.SurfaceService.closePaletteViewer(); }
    function toggle(): void { Services.SurfaceService.togglePaletteViewer(); }
    function isOpen(): bool { return Services.SurfaceService.paletteViewerVisible; }

    IpcHandler {
        target: "qe-palette"

        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function toggle(): void { root.toggle(); }
        function isOpen(): bool { return root.isOpen(); }
    }
}
