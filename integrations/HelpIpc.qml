import Quickshell
import Quickshell.Io
import "../services" as Services

Scope {
    IpcHandler {
        target: "qe-help"
        function open(): void { Services.HelpService.refresh(); }
        function close(): void { Services.HelpService.close(); }
        function toggle(): void {
            if (Services.SurfaceService.helpVisible) Services.HelpService.close();
            else Services.HelpService.refresh();
        }
        function isOpen(): bool { return Services.SurfaceService.helpVisible; }
    }
}
