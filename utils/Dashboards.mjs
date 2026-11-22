// Dashboard catalogue: the authoritative list of QE dashboards and their static
// identity. Dashboard actions and namespaced `qe-<id>` IPC targets derive from it.
// Live presentation (header actions, fallback tool, teardown) belongs to each
// dashboard's own content.
export const dashboards = Object.freeze([
    Object.freeze({
        id: "audio",
        title: "Audio",
        genericName: "QE audio controls",
        keywords: Object.freeze(["audio", "sound", "volume", "speaker", "microphone"]),
        icon: "equalizer"
    }),
    Object.freeze({
        id: "bluetooth",
        title: "Bluetooth",
        genericName: "QE Bluetooth controls",
        keywords: Object.freeze(["bluetooth", "devices", "pairing", "headphones"]),
        icon: "bluetooth"
    }),
    Object.freeze({
        id: "network",
        title: "Network",
        genericName: "QE network controls",
        keywords: Object.freeze(["network", "wifi", "wi-fi", "wireless", "ethernet", "internet"]),
        icon: "wifi"
    }),
    Object.freeze({
        id: "ai-quota",
        title: "AI Usage",
        genericName: "QE AI usage limits",
        keywords: Object.freeze(["ai", "usage", "quota", "limits", "claude", "openai", "opencode"]),
        icon: "robot_2"
    })
]);

export const dashboardIds = Object.freeze(dashboards.map(dashboard => dashboard.id));

export function dashboardFor(id) {
    return dashboards.find(dashboard => dashboard.id === id) || null;
}

export function dashboardTitle(id) {
    const dashboard = dashboardFor(id);
    return dashboard ? dashboard.title : "";
}

export function ipcTarget(id) {
    return `qe-${id}`;
}

// Launcher dashboard actions: one per catalogued dashboard, toggled through the
// shared surface-routing contract.
export const dashboardActions = Object.freeze(dashboards.map(dashboard => Object.freeze({
    id: `qe-dashboard-${dashboard.id}`,
    name: `${dashboard.title} Dashboard`,
    genericName: dashboard.genericName,
    comment: `Toggle the QE ${dashboard.title} dashboard`,
    keywords: Object.freeze(dashboard.keywords.concat(["dashboard", "qe"])),
    icon: dashboard.icon,
    actionId: dashboard.id
})));
