import Quickshell
import Quickshell.Io
import "../services" as Services

Scope {
    id: root

    IpcHandler {
        target: "qe-control-center"
        function open(): void { Services.SurfaceService.openControlCenter(); }
        function close(): void { Services.SurfaceService.closeControlCenter(); }
        function toggle(): void { Services.SurfaceService.toggleControlCenter(); }
        function isOpen(): bool { return Services.SurfaceService.controlCenterVisible; }
    }
}
