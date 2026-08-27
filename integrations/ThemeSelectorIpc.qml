import Quickshell
import Quickshell.Io
import "../services" as Services

Scope {
    id: root

    function open(): void { Services.SurfaceService.openThemeSelector(); }
    function close(): void { Services.SurfaceService.closeThemeSelector(); }
    function toggle(): void { Services.SurfaceService.toggleThemeSelector(); }
    function isOpen(): bool { return Services.SurfaceService.themeSelectorVisible; }
    function activeTheme(): string { return Services.ThemeService.activeThemeId; }
    function operation(): string { return Services.ThemeService.operation; }
    function externalOperation(): string { return Services.ThemeService.externalOperation; }
    function applyTheme(id: string): bool {
        if (id === Services.ThemeService.activeThemeId) return true;
        return Services.ThemeService.requestTheme(id);
    }

    IpcHandler {
        target: "qe-theme"

        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function toggle(): void { root.toggle(); }
        function isOpen(): bool { return root.isOpen(); }
        function activeTheme(): string { return root.activeTheme(); }
        function operation(): string { return root.operation(); }
        function externalOperation(): string { return root.externalOperation(); }
        function applyTheme(id: string): bool { return root.applyTheme(id); }
    }
}
