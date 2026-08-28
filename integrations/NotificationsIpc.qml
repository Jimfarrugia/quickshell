import Quickshell
import Quickshell.Io
import "../services" as Services

Scope {
    id: root

    function open(): void { Services.SurfaceService.openNotificationCenter(); }
    function close(): void { Services.SurfaceService.closeNotificationCenter(); }
    function toggle(): void { Services.SurfaceService.toggleNotificationCenter(); }
    function isOpen(): bool { return Services.SurfaceService.notificationCenterVisible; }
    function owner(): string { return Services.NotificationService.owner; }
    function ready(): bool { return Services.NotificationService.ready; }
    function dnd(): bool { return Services.NotificationService.dnd; }
    function setDnd(value: bool): bool { return Services.NotificationService.setDnd(value); }
    function clearHistory(): void { Services.NotificationService.clearHistory(); }

    IpcHandler {
        target: "qe-notifications"

        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function toggle(): void { root.toggle(); }
        function isOpen(): bool { return root.isOpen(); }
        function owner(): string { return root.owner(); }
        function ready(): bool { return root.ready(); }
        function dnd(): bool { return root.dnd(); }
        function setDnd(value: bool): bool { return root.setDnd(value); }
        function clearHistory(): void { root.clearHistory(); }
    }
}
