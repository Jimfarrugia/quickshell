pragma ComponentBehavior: Bound

import QtQml
import Quickshell
import Quickshell.Io
import "../services" as Services
import "../utils/Dashboards.mjs" as Dashboards

Scope {
    id: root
    property var controller
    function openDashboard(id) { Services.SurfaceService.openDashboard(id, null, "right"); }
    function toggleDashboard(id) {
        if (controller.isOpen(id)) controller.close();
        else openDashboard(id);
    }

    IpcHandler {
        target: "qe-dashboard"
        function open(id: string): void {
            root.openDashboard(id);
        }
        function close(): void { root.controller.close(); }
        function toggle(id: string): void {
            root.toggleDashboard(id);
        }
        function isOpen(id: string): bool {
            return root.controller.isOpen(id);
        }
    }

    // One namespaced target per catalogued dashboard (ADR-016, ADR-033).
    Variants {
        model: Dashboards.dashboardIds
        delegate: Component {
            IpcHandler {
                id: handler
                required property string modelData
                target: Dashboards.ipcTarget(modelData)
                function open(): void { root.openDashboard(handler.modelData); }
                function close(): void { if (root.controller.isOpen(handler.modelData)) root.controller.close(); }
                function toggle(): void { root.toggleDashboard(handler.modelData); }
                function isOpen(): bool { return root.controller.isOpen(handler.modelData); }
            }
        }
    }
}
