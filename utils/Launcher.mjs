function text(value) {
    return String(value || "");
}

export function normalize(value) {
    return text(value).toLocaleLowerCase().replace(/[^\p{L}\p{N}]+/gu, " ").trim().replace(/\s+/g, " ");
}

export function tokens(value) { return normalize(value).split(" ").filter(Boolean); }

export function isEligible(entry) {
    return entry && (!entry.isValid || entry.isValid()) && !entry.noDisplay
        && text(entry.name).trim() && Array.from(entry.command || []).length > 0;
}

function fields(entry) {
    return [normalize(entry.name), normalize(entry.genericName),
        ...(Array.from(entry.keywords || []).map(normalize)), normalize(entry.comment)];
}

function relevance(entry, query) {
    const queryTokens = tokens(query);
    if (!queryTokens.length) return [0];
    const searchable = fields(entry);
    let score = 0;
    for (const token of queryTokens) {
        const fieldScore = searchable.map((field, index) => {
            if (field === token) return 300 - index * 10;
            if (field.startsWith(`${token} `) || field.startsWith(token)) return 200 - index * 10;
            if (field.split(" ").some(part => part === token)) return 100 - index * 10;
            if (field.includes(token)) return 10 - index;
            return 0;
        });
        if (!fieldScore.some(value => value > 0)) return null;
        score += Math.max(...fieldScore);
    }
    return [score, ...searchable.map((field, index) => field === normalize(query) ? 100 - index : 0)];
}

export function rank(entries, query, usage = {}) {
    return Array.from(entries || []).filter(isEligible).map(entry => ({
        entry,
        relevance: relevance(entry, query),
        launchCount: Number(usage[entry.id]?.launchCount || 0),
        name: normalize(entry.name),
        id: text(entry.id)
    })).filter(item => item.relevance !== null).sort((a, b) => {
        if (a.relevance[0] !== b.relevance[0]) return b.relevance[0] - a.relevance[0];
        if (a.launchCount !== b.launchCount)
            return b.launchCount - a.launchCount;
        if (a.name !== b.name) return a.name.localeCompare(b.name);
        return a.id.localeCompare(b.id);
    }).map(item => item.entry);
}

export function validateUsage(document) {
    if (!document || document.schemaVersion !== 1 || !document.entries || typeof document.entries !== "object")
        return null;
    const records = Object.entries(document.entries);
    if (records.some(([, value]) => !value || !Number.isInteger(value.launchCount) || value.launchCount < 0))
        return null;
    return Object.fromEntries(records.map(([id, value]) => [id, { launchCount: value.launchCount }]));
}

export function boundedUsage(usage, ids) {
    const allowed = new Set(ids);
    const records = Object.keys(usage).map(id => [id, usage[id]])
        .filter(([id]) => allowed.has(id));
    records.sort(([, a], [, b]) => b.launchCount - a.launchCount);
    const bounded = {};
    for (const [id, record] of records.slice(0, 512)) bounded[id] = record;
    return bounded;
}
