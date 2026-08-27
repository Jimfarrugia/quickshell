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
    readonly property string defaultTheme: Services.DefaultsService.defaultTheme
    readonly property string activeTheme: Services.ThemeService.activeThemeId

    TestSurface {}
    BarHost {}
    ThemeSelectorIpc {}
    WallpaperSelectorIpc {}
    ExternalThemeAdapter {
        id: externalThemeAdapter
    }
    MatugenAdapter {
        id: matugenAdapter
    }
    WallpaperAdapter {
        id: wallpaperAdapter
    }
    WallpaperCacheAdapter {
        id: wallpaperCacheAdapter
    }
    WallpaperPromotionAdapter {
        id: wallpaperPromotionAdapter
    }

    WallpaperExternalThemeAdapter {
        id: wallpaperExternalThemeAdapter
    }

    QS.LazyLoader {
        active: Services.SurfaceService.themeSelectorVisible
        source: "modules/theme/ThemeSelector.qml"
    }

    QS.LazyLoader {
        active: Services.SurfaceService.wallpaperSelectorVisible
        source: "modules/wallpaper/WallpaperSelector.qml"
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

    Binding {
        target: Services.WallpaperService
        property: "matugenAdapter"
        value: matugenAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: Services.WallpaperService
        property: "wallpaperAdapter"
        value: wallpaperAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: Services.WallpaperService
        property: "cacheAdapter"
        value: wallpaperCacheAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: Services.WallpaperService
        property: "promotionAdapter"
        value: wallpaperPromotionAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }

    Binding {
        target: Services.WallpaperService
        property: "externalThemeAdapter"
        value: wallpaperExternalThemeAdapter
        restoreMode: Binding.RestoreBindingOrValue
    }
}
