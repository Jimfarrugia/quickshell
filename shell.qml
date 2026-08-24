//@ pragma UseQApplication

import Quickshell
import Quickshell as QS
import "services" as Services
import "modules/test_surface"
import "modules/bar"

ShellRoot {
    // Referencing the singletons here establishes deterministic startup ownership.
    readonly property string shellDirectory: Services.PathsService.shellDirectory
    readonly property string activeTheme: Services.ThemeService.activeThemeId

    TestSurface {}
    BarHost {}

    QS.LazyLoader {
        active: Services.ConfigService.config.bar.trayHostEnabled
        source: "integrations/TrayIntegration.qml"
        onItemChanged: Services.TrayService.integration = item
    }
}
