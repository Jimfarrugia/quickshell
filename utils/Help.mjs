const CATEGORIES = ["keybindings", "commands"];
const MAX_ID_LENGTH = 128;
const MAX_TEXT_LENGTH = 512;
const MAX_ENTRIES = 256;

function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
}

function text(value, field, maximum = MAX_TEXT_LENGTH) {
    return typeof value === "string" && value.trim() !== ""
        && value.length <= maximum ? value : null;
}

export function categories() { return CATEGORIES.slice(); }

export function validateEntry(entry, index = 0) {
    const errors = [];
    if (!isObject(entry)) return { entry: null, errors: [`entries[${index}]: expected an object`] };
    const allowed = new Set(["id", "category", "title", "shortcut", "command"]);
    for (const key of Object.keys(entry))
        if (!allowed.has(key)) errors.push(`entries[${index}].${key}: unsupported property`);
    const id = text(entry.id, "id", MAX_ID_LENGTH);
    const category = CATEGORIES.includes(entry.category) ? entry.category : null;
    const title = text(entry.title, "title");
    if (!id) errors.push(`entries[${index}].id: expected a non-empty string of at most ${MAX_ID_LENGTH} characters`);
    if (!category) errors.push(`entries[${index}].category: expected 'keybindings' or 'commands'`);
    if (!title) errors.push(`entries[${index}].title: expected a non-empty string of at most ${MAX_TEXT_LENGTH} characters`);
    for (const field of ["shortcut", "command"]) {
        if (entry[field] !== undefined && !text(entry[field], field))
            errors.push(`entries[${index}].${field}: expected a non-empty string of at most ${MAX_TEXT_LENGTH} characters`);
    }
    if (errors.length) return { entry: null, errors };
    const normalized = { id, category, title };
    if (entry.shortcut !== undefined) normalized.shortcut = entry.shortcut;
    if (entry.command !== undefined) normalized.command = entry.command;
    return {
        entry: normalized,
        errors: []
    };
}

export function validateCatalog(document, boundary = "help") {
    if (!isObject(document)) return { entries: [], errors: [`${boundary}: root must be an object`] };
    if (document.schemaVersion !== 1)
        return { entries: [], errors: [`${boundary}.schemaVersion: expected 1`] };
    if (!Array.isArray(document.entries))
        return { entries: [], errors: [`${boundary}.entries: expected an array`] };
    const rootKeys = Object.keys(document);
    if (rootKeys.some(key => key !== "schemaVersion" && key !== "entries"))
        return { entries: [], errors: [`${boundary}: unsupported property`] };
    if (document.entries.length > MAX_ENTRIES)
        return { entries: [], errors: [`${boundary}.entries: expected at most ${MAX_ENTRIES} entries`] };
    const entries = [];
    const errors = [];
    const ids = new Set();
    document.entries.forEach((candidate, index) => {
        const result = validateEntry(candidate, index);
        errors.push(...result.errors.map(error => `${boundary}.${error}`));
        if (result.entry && !ids.has(result.entry.id)) {
            ids.add(result.entry.id);
            entries.push(result.entry);
        } else if (result.entry) {
            errors.push(`${boundary}.entries[${index}].id: duplicate ID`);
        }
    });
    return { entries, errors };
}

function normalize(value) {
    return String(value || "").toLocaleLowerCase()
        .replace(/[^\p{L}\p{N}]+/gu, " ").trim().replace(/\s+/g, " ");
}

export function search(entries, query) {
    const normalizedQuery = normalize(query);
    if (!normalizedQuery) return Array.from(entries || []);
    const queryTokens = normalizedQuery.split(" ");
    return Array.from(entries || []).map((entry, index) => {
        const fields = [entry.title, entry.category, entry.shortcut, entry.command].map(normalize);
        let score = 0;
        for (const token of queryTokens) {
            const fieldScore = fields.map((field, fieldIndex) => {
                if (field === token) return 300 - fieldIndex * 10;
                if (field.startsWith(token)) return 200 - fieldIndex * 10;
                if (field.split(" ").some(part => part === token)) return 100 - fieldIndex * 10;
                if (field.includes(token)) return 10 - fieldIndex;
                return 0;
            });
            if (!fieldScore.some(value => value > 0)) return null;
            score += Math.max(...fieldScore);
        }
        return { entry, score, index };
    }).filter(item => item !== null && item.score !== null)
        .sort((a, b) => b.score - a.score || a.index - b.index)
        .map(item => item.entry);
}
