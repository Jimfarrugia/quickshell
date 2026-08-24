// Pure transformations for /proc, /sys, and helper JSON outputs.
// These functions have no QML or Qt dependencies and are fixture-tested.

export function parseCpuStat(text, previous) {
  if (typeof text !== "string") return { ok: false, error: "cpu text is not a string" };
  const match = /^cpu\s+(\d+(?: \d+)*)/m.exec(text);
  if (!match) return { ok: false, error: "missing cpu line in /proc/stat" };
  const values = match[1].trim().split(/\s+/).map(part => parseInt(part, 10));
  if (values.length < 4) return { ok: false, error: "cpu line has too few fields" };

  const total = values.slice(0, 7).reduce((sum, value) => sum + value, 0);
  const idle = values[3] + (values[4] || 0); // idle + iowait

  if (!previous || typeof previous.total !== "number" || typeof previous.idle !== "number"
      || total < previous.total) {
    return { ok: true, usagePercent: null, total, idle };
  }

  const deltaTotal = total - previous.total;
  const deltaIdle = idle - previous.idle;
  const usage = deltaTotal > 0
    ? Math.round((100 * (deltaTotal - deltaIdle)) / deltaTotal)
    : 0;

  return {
    ok: true,
    usagePercent: Math.max(0, Math.min(100, usage)),
    total,
    idle
  };
}

export function parseMemInfo(text) {
  if (typeof text !== "string") return { ok: false, error: "meminfo text is not a string" };

  const readKb = name => {
    const pattern = new RegExp(`^${name}:\\s+(\\d+)`, "m");
    const found = pattern.exec(text);
    return found ? parseInt(found[1], 10) : null;
  };

  const total = readKb("MemTotal");
  if (total === null) return { ok: false, error: "missing MemTotal in /proc/meminfo" };

  const available = readKb("MemAvailable");
  let used;
  if (available !== null) {
    used = total - available;
  } else {
    const free = readKb("MemFree") || 0;
    const buffers = readKb("Buffers") || 0;
    const cached = readKb("Cached") || 0;
    used = total - free - buffers - cached;
  }

  return {
    ok: true,
    usedPercent: total > 0 ? Math.max(0, Math.min(100, Math.round((100 * used) / total))) : 0,
    totalKb: total,
    usedKb: Math.max(0, used)
  };
}

export function parseThermalOutput(text) {
  if (typeof text !== "string") return { ok: false, error: "thermal output is not a string" };
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch (error) {
    return { ok: false, error: `thermal JSON parse failed: ${error.message}` };
  }
  if (parsed.schemaVersion !== 1) return { ok: false, error: "thermal output schemaVersion must be 1" };
  if (!Array.isArray(parsed.sensors)) return { ok: false, error: "thermal output missing sensors array" };
  const sensors = [];
  for (const sensor of parsed.sensors) {
    if (typeof sensor !== "object" || sensor === null
        || typeof sensor.name !== "string" || typeof sensor.label !== "string"
        || typeof sensor.path !== "string" || !Number.isInteger(sensor.temp)
        || sensor.temp < -100000 || sensor.temp > 300000)
      return { ok: false, error: "thermal output contains an invalid sensor" };
    sensors.push({ name: sensor.name, label: sensor.label, path: sensor.path, temp: sensor.temp });
  }
  return { ok: true, sensors };
}

const THERMAL_PRIORITY = [
  "tctl",
  "tdie",
  "package",
  "core",
  "cpu",
  "x86_pkg_temp",
  "hwmon",
  "acpitz"
];

export function selectThermalSensor(sensors) {
  if (!Array.isArray(sensors) || sensors.length === 0) return null;

  const scored = sensors.map(sensor => {
    const key = `${sensor.label} ${sensor.name}`.toLowerCase();
    let score = 0;
    for (let index = 0; index < THERMAL_PRIORITY.length; index++) {
      if (key.includes(THERMAL_PRIORITY[index])) {
        score = THERMAL_PRIORITY.length - index;
        break;
      }
    }
    return { sensor, score };
  });

  scored.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    return b.sensor.temp - a.sensor.temp;
  });

  return scored[0].sensor;
}

export function parseDiskOutput(text) {
  if (typeof text !== "string") return { ok: false, error: "disk output is not a string" };
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch (error) {
    return { ok: false, error: `disk JSON parse failed: ${error.message}` };
  }
  if (parsed.schemaVersion !== 1) return { ok: false, error: "disk output schemaVersion must be 1" };
  if (!Array.isArray(parsed.disks)) return { ok: false, error: "disk output missing disks array" };
  const disks = [];
  for (const disk of parsed.disks) {
    if (typeof disk !== "object" || disk === null
        || typeof disk.filesystem !== "string" || typeof disk.size !== "string"
        || typeof disk.used !== "string" || typeof disk.available !== "string"
        || !/^\d+$/.test(disk.size) || !/^\d+$/.test(disk.used) || !/^\d+$/.test(disk.available)
        || !Number.isInteger(disk.percent) || disk.percent < 0 || disk.percent > 100
        || typeof disk.mount !== "string")
      return { ok: false, error: "disk output contains an invalid entry" };
    disks.push(disk);
  }
  return { ok: true, disks };
}

export function selectRootDisk(disks) {
  if (!Array.isArray(disks) || disks.length === 0) return null;
  return disks.find(disk => disk.mount === "/") || disks[0];
}
