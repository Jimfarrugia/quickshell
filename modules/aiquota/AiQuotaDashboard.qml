import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../utils/AiQuota.mjs" as AiQuota

ColumnLayout {
    id: root
    spacing: Services.ConfigService.config.appearance.spacing
    property var providerIds: Services.AiQuotaService.providerIds
    property bool registered: false

    function updateConsumer() {
        if (visible && !registered) {
            Services.AiQuotaService.registerConsumer();
            registered = true;
        } else if (!visible && registered) {
            Services.AiQuotaService.unregisterConsumer();
            registered = false;
        }
    }

    component Caption: Text {
        color: Services.ThemeService.theme.tokens.on_surface_variant
        font.family: Services.ConfigService.config.appearance.fontFamily
        font.pixelSize: Services.ConfigService.config.appearance.fontSize
        wrapMode: Text.Wrap
    }
    component Heading: Text {
        color: Services.ThemeService.theme.tokens.on_surface
        font.family: Services.ConfigService.config.appearance.fontFamily
        font.pixelSize: Services.ConfigService.config.appearance.fontSize
        font.weight: Font.DemiBold
    }
    component LimitRow: ColumnLayout {
        id: limitRow
        required property var limit
        required property string label
        required property string providerId
        property int windowIndex: 0
        Layout.fillWidth: true
        Layout.topMargin: windowIndex > 0 ? 4 : 0
        spacing: 4
        RowLayout {
            objectName: `${limitRow.providerId}-${limitRow.label}-heading`
            Layout.fillWidth: true
            Layout.bottomMargin: 2
            Heading { text: limitRow.label; Layout.fillWidth: true; Layout.minimumWidth: 0 }
            Caption {
                objectName: `${limitRow.providerId}-${limitRow.label}-remaining`
                text: limitRow.limit.status === "ok"
                    ? `${AiQuota.formatPercent(limitRow.limit.remainingPercent)}% remaining${limitRow.limit.freshness === "stale" ? " (stale)" : ""}`
                    : "Unavailable"
                Layout.minimumWidth: 0
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
            }
        }
        ProgressBar {
            id: progress
            objectName: `${limitRow.providerId}-${limitRow.label}-progress`
            Layout.fillWidth: true
            Layout.bottomMargin: 2
            implicitHeight: 6
            from: 0
            to: 100
            value: parent.limit.status === "ok" ? parent.limit.remainingPercent : 0
            indeterminate: parent.limit.status !== "ok"
            contentItem: Item {
                clip: true
                Rectangle {
                    objectName: `${limitRow.providerId}-${limitRow.label}-track`
                    anchors.fill: parent
                    radius: 0
                    color: Services.ThemeService.theme.tokens.surface_low
                }
                Rectangle {
                    id: determinateFill
                    visible: !progress.indeterminate
                    width: progress.visualPosition * parent.width
                    height: parent.height
                    radius: 3
                    color: Services.ThemeService.theme.tokens.primary
                }
                Rectangle {
                    id: indeterminateFill
                    visible: progress.indeterminate
                    width: Math.max(24, parent.width / 4)
                    height: parent.height
                    radius: 3
                    color: Services.ThemeService.theme.tokens.warning
                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        running: progress.indeterminate
                        NumberAnimation { from: -indeterminateFill.width; to: progress.width; duration: 1000 }
                    }
                }
            }
        }
        Caption {
            objectName: `${limitRow.providerId}-${limitRow.label}-details`
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: parent.limit.status === "ok"
                ? `Resets in <b>${AiQuota.formatTimeUntil(parent.limit.resetsAt)}</b> on <b>${AiQuota.formatReset(parent.limit.resetsAt)}</b>`
                : (parent.limit.error ? parent.limit.error.code : "No confirmed data")
            textFormat: Text.RichText
            color: parent.limit.status === "ok" && parent.limit.freshness !== "stale"
                ? Services.ThemeService.theme.tokens.on_surface_variant
                : Services.ThemeService.theme.tokens.warning
        }
    }
    component ProviderSection: ColumnLayout {
        required property string providerId
        property int sectionIndex: -1
        readonly property var provider: Services.AiQuotaService.provider(providerId)
        Layout.fillWidth: true
        Layout.bottomMargin: sectionIndex >= 0 && sectionIndex < root.providerIds.length - 1
            ? Math.max(0, 20 - root.spacing) : 0
        spacing: 8
        Rectangle {
            objectName: `${providerId}-section`
            Layout.fillWidth: true
            implicitHeight: sectionContent.implicitHeight + 24
            radius: Services.ConfigService.config.appearance.radius
            color: Services.ThemeService.theme.tokens.surface
            border.width: Services.ConfigService.config.appearance.borderWidth
            border.color: provider.freshness === "stale"
                ? Services.ThemeService.theme.tokens.warning : Services.ThemeService.theme.tokens.outline_variant
            ColumnLayout {
                id: sectionContent
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                RowLayout {
                    objectName: `${providerId}-heading`
                    Layout.fillWidth: true
                    Layout.bottomMargin: 4
                    Heading { objectName: `${providerId}-provider`; text: provider.label; Layout.fillWidth: true; Layout.minimumWidth: 0; elide: Text.ElideRight }
                    Caption {
                        objectName: `${providerId}-freshness`
                        visible: provider.freshness !== "current"
                        text: `${provider.freshness} data`
                        color: Services.ThemeService.theme.tokens.warning
                    }
                }
                Caption {
                    visible: provider.lastError !== null
                    text: provider.lastError ? provider.lastError.summary : ""
                    color: Services.ThemeService.theme.tokens.warning
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                }
                LimitRow { providerId: parent.parent.parent.providerId; label: "5-hour Limit"; limit: provider.fiveHour; windowIndex: 0 }
                LimitRow { providerId: parent.parent.parent.providerId; label: "Weekly Limit"; limit: provider.weekly; windowIndex: 1 }
                LimitRow { providerId: parent.parent.parent.providerId; label: "Monthly Limit"; limit: provider.monthly; windowIndex: 2; visible: parent.parent.parent.providerId === "opencode" }
            }
        }
    }

    Repeater {
        model: root.providerIds
        delegate: ProviderSection {
            required property int index
            sectionIndex: index
            providerId: root.providerIds[index]
        }
    }
    Caption {
        objectName: "last-checked"
        Layout.topMargin: Math.max(0, 20 - root.spacing)
        visible: Services.AiQuotaService.operation === "pending"
            || Services.AiQuotaService.lastUpdated !== null
        color: Services.ThemeService.theme.tokens.on_surface_disabled
        text: Services.AiQuotaService.operation === "pending"
            ? "Refreshing..."
            : (Services.AiQuotaService.lastUpdated
                ? `Updated ${AiQuota.formatReset(Services.AiQuotaService.lastUpdated)}` : "")
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        width: root.width
        elide: Text.ElideRight
    }
    onVisibleChanged: updateConsumer()
    Component.onCompleted: updateConsumer()
    Component.onDestruction: if (registered) Services.AiQuotaService.unregisterConsumer()
}
