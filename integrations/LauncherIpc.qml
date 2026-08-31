import Quickshell
import Quickshell.Io
import "../services" as Services

Scope {
    IpcHandler {
        target: "qe-launcher"
        function open(): void { Services.LauncherService.open(); }
        function close(): void { Services.LauncherService.close(); }
        function toggle(): void { Services.LauncherService.toggle(); }
        function isOpen(): bool { return Services.SurfaceService.launcherVisible; }
    }
}
