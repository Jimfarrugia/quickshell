import assert from "node:assert/strict";
import { boundedUsage, isEligible, normalize, rank, validateUsage } from "../../utils/Launcher.mjs";

const entry = (id, name, extra = {}) => ({ id, name, command: [name.toLowerCase()], ...extra });

assert.equal(normalize("  Café-App!  Reader  "), "café app reader");
assert.equal(isEligible(entry("ok", "Visible")), true);
assert.equal(isEligible(entry("hidden", "Hidden", { noDisplay: true })), false);
assert.equal(isEligible(entry("terminal", "Terminal", { runInTerminal: true })), true);
assert.equal(isEligible(entry("empty", "Empty", { command: [] })), false);

const apps = [
  entry("z", "Beta Browser", { genericName: "Web browser" }),
  entry("a", "Alpha Editor", { keywords: ["browser"] }),
  entry("b", "Beta Browser", { genericName: "Web browser" })
];
assert.deepEqual(rank(apps, "web browser", { z: { launchCount: 99 } }).map(item => item.id), ["z", "b"]);
assert.deepEqual(rank(apps, "browser", { a: { launchCount: 1 }, z: { launchCount: 4 } }).map(item => item.id), ["a", "z", "b"]);
assert.deepEqual(rank(apps, "", { a: { launchCount: 2 }, z: { launchCount: 2 } }).map(item => item.id), ["a", "z", "b"]);
assert.deepEqual(rank(apps, "missing"), []);
assert.equal(validateUsage({ schemaVersion: 1, entries: { ok: { launchCount: 2 }, bad: { launchCount: -1 } } }), null);
assert.equal(validateUsage({ schemaVersion: 2, entries: {} }), null);
const many = Object.fromEntries(Array.from({ length: 513 }, (_, index) => [`id-${index}`, { launchCount: index }]));
assert.equal(Object.keys(boundedUsage(many, Object.keys(many))).length, 512);
console.log("LAUNCHER_TEST_PASSED");
