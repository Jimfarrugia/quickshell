import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import {
  parseCpuStat,
  parseMemInfo,
  parseThermalOutput,
  selectThermalSensor,
  parseDiskOutput,
  selectRootDisk
} from "../../utils/SystemMetrics.mjs";

const exec = promisify(execFile);
const fixture = async path => readFile(new URL(`../fixtures/system-metrics/${path}`, import.meta.url), "utf8");
const projectRoot = new URL("../..", import.meta.url).pathname;
const helperPath = new URL("../../scripts/qe-system-metrics.sh", import.meta.url).pathname;
const fixtureRoot = new URL("../fixtures/system-metrics", import.meta.url).pathname;

// ----- /proc parsers -----
const statText = await fixture("proc/stat");
const firstCpu = parseCpuStat(statText, null);
assert.equal(firstCpu.ok, true);
assert.equal(firstCpu.usagePercent, null);
assert.equal(typeof firstCpu.total, "number");
assert.equal(typeof firstCpu.idle, "number");

const previous = { total: firstCpu.total - 1000, idle: firstCpu.idle - 200 };
const secondCpu = parseCpuStat(statText, previous);
assert.equal(secondCpu.ok, true);
assert.equal(secondCpu.usagePercent, 80);

const malformedCpu = parseCpuStat("no cpu line here", null);
assert.equal(malformedCpu.ok, false);

const memInfo = parseMemInfo(await fixture("proc/meminfo"));
assert.equal(memInfo.ok, true);
assert.equal(memInfo.usedPercent, 50);
assert.equal(memInfo.totalKb, 16000000);
assert.equal(memInfo.usedKb, 8000000);

const badMem = parseMemInfo("SwapFree: 0 kB\n");
assert.equal(badMem.ok, false);

// ----- thermal helper and selection -----
const thermalResult = await exec("bash", [helperPath, "--mode", "thermal", "--root", fixtureRoot]);
const thermal = parseThermalOutput(thermalResult.stdout);
assert.equal(thermal.ok, true);
assert.equal(thermal.sensors.length, 2);

const selected = selectThermalSensor(thermal.sensors);
assert.equal(selected.name, "k10temp");
assert.equal(selected.label, "Tctl");
assert.equal(selected.temp, 42850);

assert.equal(selectThermalSensor([]), null);

// ----- disk helper and selection -----
const diskResult = await exec("bash", [helperPath, "--mode", "disk", "--root", fixtureRoot]);
const disk = parseDiskOutput(diskResult.stdout);
assert.equal(disk.ok, true);
assert.equal(disk.disks.length, 1);
assert.equal(disk.disks[0].mount, "/");
assert.equal(disk.disks[0].percent, 40);

const rootDisk = selectRootDisk(disk.disks);
assert.equal(rootDisk.filesystem, "/dev/nvme0n1p2");
assert.equal(selectRootDisk([]), null);

// ----- helper failure handling -----
const badThermal = parseThermalOutput("not json");
assert.equal(badThermal.ok, false);
assert.equal(parseThermalOutput('{"sensors":[]}').ok, false);
assert.equal(parseThermalOutput('{"schemaVersion":1,"sensors":[{"name":"cpu","label":"","path":"x","temp":"hot"}]}').ok, false);
const badDisk = parseDiskOutput('{"disks": "wrong"}');
assert.equal(badDisk.ok, false);
assert.equal(parseDiskOutput('{"schemaVersion":1,"disks":[{"filesystem":"x","size":"1","used":"1","available":"0","percent":101,"mount":"/"}]}').ok, false);
assert.equal(parseDiskOutput('{"schemaVersion":1,"disks":[{"filesystem":"x","size":"large","used":"1","available":"0","percent":1,"mount":"/"}]}').ok, false);

console.log("system-metrics fixtures passed");
