import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const source = await readFile(new URL("../../lock.qml", import.meta.url), "utf8");
const surfaceSource = await readFile(new URL("../../lock/LockSurface.qml", import.meta.url), "utf8");
const backgroundSource = await readFile(new URL("../../lock/LockBackground.qml", import.meta.url), "utf8");

assert.match(source, /Lock\.LockSurface\s*\{[\s\S]*?controller:\s*lockController\b/);
assert.match(source, /Lock\.LockController\s*\{\s*id:\s*lockController\b/);
assert.doesNotMatch(source, /controller:\s*controller\b/);
assert.match(surfaceSource, /TextInput\s*\{[\s\S]*?clip:\s*true\b/);
assert.match(surfaceSource, /onEnabledChanged:[\s\S]*?forceActiveFocus\(\)/);
assert.match(backgroundSource, /PreserveAspectCrop/);
assert.match(backgroundSource, /sourceSize: Qt\.size\(root\.maxImageWidth, root\.maxImageHeight\)/);
assert.match(backgroundSource, /asynchronous: false/);
assert.match(backgroundSource, /source: composition/);
assert.match(backgroundSource, /radius: 12/);
assert.match(backgroundSource, /samples: 25/);
assert.match(backgroundSource, /GradientStop \{ position: 0\.0; color: "#00000000" \}/);
assert.match(backgroundSource, /GradientStop \{ position: 1\.0; color: "#ff000000" \}/);

console.log("LOCK_ENTRY_TEST_PASSED");
