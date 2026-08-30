pragma Singleton

import Quickshell
import "../integrations" as Integrations

Singleton {
    property var integration: nativeIntegration
    readonly property string availability: integration.availability
    readonly property string freshness: integration.freshness
    readonly property var lastUpdated: integration.lastUpdated
    readonly property var lastError: integration.lastError
    readonly property string operation: integration.operation
    readonly property bool present: integration.present
    readonly property int percentage: integration.percentage
    readonly property bool charging: integration.charging
    readonly property bool fullyCharged: integration.fullyCharged
    readonly property int timeToEmptySeconds: integration.timeToEmptySeconds
    readonly property int timeToFullSeconds: integration.timeToFullSeconds
    readonly property int remainingTimeSeconds: charging ? timeToFullSeconds : timeToEmptySeconds
    readonly property string remainingTimeEstimate: formatDuration(remainingTimeSeconds)
    readonly property string remainingTimeText: fullyCharged
        ? "Fully charged."
        : (charging
            ? `Time to full: ${formatDuration(timeToFullSeconds)}`
            : `Time to empty: ${formatDuration(timeToEmptySeconds)}`)
    readonly property string iconName: integration.iconName

    function formatDuration(seconds) {
        if (!Number.isFinite(seconds) || seconds <= 0) return "unavailable";
        const totalMinutes = Math.max(1, Math.round(seconds / 60));
        const hours = Math.floor(totalMinutes / 60);
        const minutes = totalMinutes % 60;
        if (hours === 0) return `${minutes}m`;
        if (minutes === 0) return `${hours}h`;
        return `${hours}h ${minutes}m`;
    }

    Integrations.UPowerIntegration { id: nativeIntegration }
}
