import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import {
  parseDiscoverOutput,
  parseReadOutput,
  parseSetOutput,
  selectBacklightDevice,
  selectDevice,
  parseSysfsSnapshot,
  clampPercent,
  percentToRaw
} from "../../utils/Brightness.mjs";

const exec = promisify(execFile);
const fixture = async path => readFile(new URL(`../fixtures/brightness/${path}`, import.meta.url), "utf8");
const projectRoot = new URL("../..", import.meta.url).pathname;
const helperPath = new URL("../../scripts/qe-brightness.sh", import.meta.url).pathname;
const fixtureRoot = new URL("../fixtures/brightness", import.meta.url).pathname;

// ----- parser validation -----
const validDiscover = parseDiscoverOutput('{"schemaVersion":1,"devices":[{"name":"intel_backlight","class":"backlight","brightness":530,"maxBrightness":1060,"percent":50}]}');
assert.equal(validDiscover.ok, true);
assert.equal(validDiscover.devices.length, 1);
assert.equal(selectBacklightDevice(validDiscover.devices).name, "intel_backlight");

const nonBacklight = parseDiscoverOutput('{"schemaVersion":1,"devices":[{"name":"tpacpi::power","class":"leds","brightness":255,"maxBrightness":255,"percent":100}]}');
assert.equal(nonBacklight.ok, true);
assert.equal(selectBacklightDevice(nonBacklight.devices), null);
const keyboardDevices = parseDiscoverOutput('{"schemaVersion":1,"devices":[{"name":"tpacpi::power","class":"leds","brightness":255,"maxBrightness":255,"percent":100},{"name":"tpacpi::kbd_backlight","class":"leds","brightness":1,"maxBrightness":2,"percent":50}]}');
assert.equal(selectDevice(keyboardDevices.devices, "leds").name, "tpacpi::kbd_backlight");

const emptyDiscover = parseDiscoverOutput('{"schemaVersion":1,"devices":[]}');
assert.equal(emptyDiscover.ok, true);
assert.equal(selectBacklightDevice(emptyDiscover.devices), null);

const validRead = parseReadOutput('{"schemaVersion":1,"name":"intel_backlight","brightness":530,"maxBrightness":1060,"percent":50}');
assert.equal(validRead.ok, true);
assert.equal(validRead.percent, 50);

assert.equal(parseReadOutput('not json').ok, false);
assert.equal(parseReadOutput('{"schemaVersion":2}').ok, false);
assert.equal(parseReadOutput('{"schemaVersion":1,"name":"../etc/passwd","brightness":1,"maxBrightness":10,"percent":10}').ok, false);
assert.equal(parseReadOutput('{"schemaVersion":1,"name":"dev","brightness":-1,"maxBrightness":10,"percent":10}').ok, false);
assert.equal(parseReadOutput('{"schemaVersion":1,"name":"dev","brightness":1,"maxBrightness":0,"percent":10}').ok, false);
assert.equal(parseReadOutput('{"schemaVersion":1,"name":"dev","brightness":1,"maxBrightness":10,"percent":101}').ok, false);
assert.equal(parseReadOutput('{"schemaVersion":1,"name":"dev","brightness":11,"maxBrightness":10,"percent":100}').ok, false);
assert.equal(parseReadOutput('{"schemaVersion":1,"name":"dev","brightness":1,"maxBrightness":10,"percent":11}').ok, false);

const sysfs = parseSysfsSnapshot("530\n", "1060\n", "intel_backlight", "backlight");
assert.equal(sysfs.ok, true);
assert.equal(sysfs.percent, 50);
assert.equal(parseSysfsSnapshot("bad", "1060", "intel_backlight", "backlight").ok, false);
assert.equal(parseSysfsSnapshot("1061", "1060", "intel_backlight", "backlight").ok, false);
assert.equal(parseSysfsSnapshot("530", "1060", "../backlight", "backlight").ok, false);

const setResult = parseSetOutput('{"schemaVersion":1,"name":"intel_backlight","brightness":106,"maxBrightness":1060,"percent":10}');
assert.equal(setResult.ok, true);
assert.equal(setResult.percent, 10);

// ----- pure transforms -----
assert.equal(clampPercent(0), 1);
assert.equal(clampPercent(1), 1);
assert.equal(clampPercent(100), 100);
assert.equal(clampPercent(101), 100);
assert.equal(clampPercent(50.4), 50);
assert.equal(clampPercent(NaN), 1);

assert.equal(percentToRaw(1, 1060), 11);
assert.equal(percentToRaw(50, 1060), 530);
assert.equal(percentToRaw(100, 1060), 1060);
assert.equal(percentToRaw(0, 1060), 11);
assert.equal(percentToRaw(101, 1060), 1060);

// ----- helper fixture contract -----
const discoverResult = await exec("bash", [helperPath, "--mode", "discover", "--root", fixtureRoot]);
const discovered = parseDiscoverOutput(discoverResult.stdout);
assert.equal(discovered.ok, true);
assert.equal(discovered.devices.length, 1);
assert.equal(discovered.devices[0].name, "intel_backlight");

const readResult = await exec("bash", [helperPath, "--mode", "read", "--root", fixtureRoot, "--device", "intel_backlight"]);
const read = parseReadOutput(readResult.stdout);
assert.equal(read.ok, true);
assert.equal(read.name, "intel_backlight");
assert.equal(read.percent, 100);

// The committed fixture must remain unchanged after the JS set test above.
const readAgain = parseReadOutput((await exec("bash", [helperPath, "--mode", "read", "--root", fixtureRoot, "--device", "intel_backlight"])).stdout);
assert.equal(readAgain.percent, 100);

const tmpRoot = new URL(`../fixtures/brightness/tmp-test-${Date.now()}`, import.meta.url).pathname;
await exec("mkdir", ["-p", `${tmpRoot}/sys/class/backlight/intel_backlight`]);
await exec("cp", [`${fixtureRoot}/sys/class/backlight/intel_backlight/max_brightness`, `${tmpRoot}/sys/class/backlight/intel_backlight/max_brightness`]);
await exec("cp", [`${fixtureRoot}/sys/class/backlight/intel_backlight/brightness`, `${tmpRoot}/sys/class/backlight/intel_backlight/brightness`]);
try {
  const setResult = await exec("bash", [helperPath, "--mode", "set", "--root", tmpRoot, "--device", "intel_backlight", "--percent", "50"]);
  const set = parseSetOutput(setResult.stdout);
  assert.equal(set.ok, true);
  assert.equal(set.percent, 50);
  assert.equal(set.brightness, 530);

  const afterRead = await exec("bash", [helperPath, "--mode", "read", "--root", tmpRoot, "--device", "intel_backlight"]);
  const after = parseReadOutput(afterRead.stdout);
  assert.equal(after.percent, 50);
} finally {
  await exec("rm", ["-rf", tmpRoot]);
}

console.log("brightness fixtures passed");
