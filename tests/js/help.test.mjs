import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { merge, search, validateCatalog } from "../../utils/Help.mjs";

const defaults = JSON.parse(await readFile(new URL("../../defaults/help.json", import.meta.url)));
const catalog = validateCatalog(defaults);
assert.deepEqual(catalog.errors, []);
assert.equal(catalog.entries[0].id, "help.toggle");

const user = validateCatalog({ schemaVersion: 1, entries: [
    { id: "launcher.toggle", category: "keybindings", title: "Custom launcher", shortcut: "Super+Space" },
    { id: "custom", category: "commands", title: "Custom command", command: "qe-custom" },
    { id: "bad", category: "other", title: "Rejected" }
]});
assert.equal(user.entries.length, 2);
assert.equal(user.errors.length, 1);
assert.equal(validateCatalog({ schemaVersion: 1, extra: true, entries: [] }).entries.length, 0);
assert.ok(validateCatalog({ schemaVersion: 1, entries: Array.from({ length: 257 }, () => ({
    id: "entry", category: "commands", title: "Entry"
})) }).errors.length > 0);
assert.ok(validateCatalog({ schemaVersion: 1, entries: [
    { id: " ", category: "commands", title: "Invalid" },
    { id: "valid", category: "commands", title: "Valid" }
]}).entries.some(entry => entry.id === "valid"));

const merged = merge(catalog.entries, user.entries);
assert.equal(merged[0].id, "help.toggle");
assert.equal(merged.find(entry => entry.id === "launcher.toggle").title, "Custom launcher");
assert.equal(merged.at(-1).id, "custom");
assert.deepEqual(search(merged, "custom launcher"), [merged.find(entry => entry.id === "launcher.toggle")]);
assert.deepEqual(search(merged, "qe custom"), [merged.find(entry => entry.id === "custom")]);

console.log("HELP_TEST_PASSED");
