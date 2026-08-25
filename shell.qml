//@ pragma UseQApplication

import QtQml
import Quickshell
import Quickshell as QS
import "services" as Services
import "integrations"
import "modules/test_surface"
import "modules/bar"

ShellRoot {
    // Referencing the singletons here establishes deterministic startup ownership.
    readonly property string shellDirectory: Services.PathsService.shellDirectory
    readonly property string activeTheme: Services.ThemeService.activeThemeId

    TestSurface {}
    BarHost {}
    ThemeSelectorIpc {}
    ExternalThemeAdapter {
        id: externalThemeAdapter
    }

    QS.LazyLoader {
        active: Services.SurfaceService.themeSelectorVisible
        source: "modules/theme/ThemeSelector.qml"
    }

    QS.LazyLoader {
        active: Services.ConfigService.config.bar.trayHostEnabled
        source: "integrations/TrayIntegration.qml"
        onItemChanged: Services.TrayService.integration = item
    }

    Binding {
        target: Services.ThemeService
        property: "externalAdapter"
        value: externalThemeAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }
}
