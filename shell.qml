//@ pragma UseQApplication

import QtQml
import Quickshell
import Quickshell as QS
import Quickshell.Networking
import "services" as Services
import "integrations"
import "modules/test_surface"
import "modules/bar"
import "components"
import "tests/fixtures/qml" as Fixtures

ShellRoot {
    readonly property bool ethernetPreview: Quickshell.env("QE_NETWORK_ETHERNET_PREVIEW") === "1"

    Fixtures.FakeNetworkDashboardIntegration {
        id: ethernetNetworkFixture
        availability: "available"
        connectionType: "wired"
        interfaceName: "fixture0"
        wiredInterface: "fixture0"
        selectedDevice: ({type: DeviceType.Wired})
        selectedDeviceConnected: true
        selectedDeviceLabel: "fixture0"
        linkSpeed: 1000
        wifiDevice: null
        wifiEnabled: false
    }
    Fixtures.FakeNetworkAddressIntegration { id: ethernetAddressFixture }

    DashboardController { id: dashboardController }
    Binding {
        target: Services.SurfaceService
        property: "dashboardController"
        value: dashboardController
        restoreMode: Binding.RestoreBindingOrValue
    }
    // Referencing the singletons here establishes deterministic startup ownership.
    readonly property string shellDirectory: Services.PathsService.shellDirectory
    readonly property string defaultTheme: Services.DefaultsService.defaultTheme
    readonly property string activeTheme: Services.ThemeService.activeThemeId

    TestSurface {}
    BarHost { dashboardController: dashboardController }
    ThemeSelectorIpc {}
    WallpaperSelectorIpc {}
    PaletteViewerIpc {}
    NotificationsIpc {}
    LauncherIpc {}
    HelpIpc {}
    DashboardIpc { controller: dashboardController }
    ActionsIpc {}
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
        active: Services.SurfaceService.launcherVisible
        source: "modules/launcher/Launcher.qml"
    }

    QS.LazyLoader {
        active: Services.SurfaceService.helpVisible
        source: "modules/help/Help.qml"
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
        active: Services.SurfaceService.paletteViewerVisible
        source: "modules/palette/PaletteViewer.qml"
    }

    QS.LazyLoader {
        active: Services.SurfaceService.notificationCenterVisible
        source: "modules/notifications/NotificationCenter.qml"
    }

    QS.LazyLoader {
        active: dashboardController.visible
        source: "components/DashboardShell.qml"
        onItemChanged: if (item) item.controller = dashboardController
    }

    QS.LazyLoader {
        active: Services.ConfigService.config.osd.enabled
        source: "modules/osd/OSDHost.qml"
    }

    QS.LazyLoader {
        active: Services.ConfigService.config.notifications.enabled
        source: "integrations/NotificationsIntegration.qml"
        onItemChanged: Services.NotificationService.integration = item
    }

    QS.LazyLoader {
        active: Services.ConfigService.config.notifications.enabled
        source: "modules/notifications/NotificationPopupHost.qml"
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

    Component.onCompleted: {
        if (!ethernetPreview) return;
        Services.NetworkService.integration = ethernetNetworkFixture;
        Services.NetworkService.addressIntegration = ethernetAddressFixture;
    }
}
