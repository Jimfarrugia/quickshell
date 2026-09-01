import Quickshell
import Quickshell.Io
import "../services" as Services

Scope {
    id: root
    property var controller
    function openDashboard(id) { controller.open(id, null, "right"); }
    function toggleDashboard(id) {
        if (controller.isOpen(id)) controller.close();
        else openDashboard(id);
    }

    IpcHandler {
        target: "qe-dashboard"
        function open(id: string): void {
            root.openDashboard(id);
        }
        function close(): void { controller.close(); }
        function toggle(id: string): void {
            root.toggleDashboard(id);
        }
        function isOpen(id: string): bool {
            return controller.isOpen(id);
        }
    }

    IpcHandler {
        target: "qe-audio"
        function open(): void { root.openDashboard("audio"); }
        function close(): void { if (controller.isOpen("audio")) controller.close(); }
        function toggle(): void { root.toggleDashboard("audio"); }
        function isOpen(): bool { return controller.isOpen("audio"); }
    }
}
