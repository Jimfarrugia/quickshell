import Quickshell
import Quickshell.Io
import "../services" as Services

Scope {
    property var controller
    IpcHandler {
        target: "qe-dashboard"
        function open(id: string): void {
            controller.open(id, null, "right");
        }
        function close(): void { controller.close(); }
        function toggle(id: string): void {
            if (controller.isOpen(id)) controller.close();
            else open(id);
        }
        function isOpen(id: string): bool {
            return controller.isOpen(id);
        }
    }
}
