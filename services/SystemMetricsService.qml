pragma Singleton

import QtQuick
import Quickshell
import "../utils/SystemMetrics.mjs" as SystemMetrics
import "../integrations" as Integrations

// Owns normalized CPU, memory, disk, and temperature state, per-metric health,
// and consumer-aware polling lifecycle. All parsing is delegated to pure JS.
Singleton {
  id: root

  readonly property bool cpuConsumer: metricConfigured("cpu")
  readonly property bool memoryConsumer: metricConfigured("memory")
  readonly property bool diskConsumer: metricConfigured("disk")
  readonly property bool temperatureConsumer: metricConfigured("temperature")
  readonly property bool hasConsumer: cpuConsumer || memoryConsumer || diskConsumer || temperatureConsumer

  readonly property bool polling: hasConsumer
  readonly property string availability: aggregateAvailability()
  readonly property string freshness: aggregateFreshness()
  readonly property var lastUpdated: latestUpdate()
  readonly property var lastError: cpu.lastError || memory.lastError || disk.lastError || temperature.lastError
  readonly property string operation: "idle"

  property var cpu: makeState(0)
  property var memory: makeState(0)
  property var disk: makeState(0)
  property var temperature: makeState(0, "")

  property var procAdapter: realProcAdapter
  property var helperAdapter: realHelperAdapter
  readonly property string cpuHoverText: metricAvailable(cpu)
    ? `Usage: ${cpu.value}%\nSource: /proc/stat\nStatus: ${statusText(cpu.freshness)}`
    : "CPU unavailable"
  readonly property string memoryHoverText: metricAvailable(memory)
    ? `Used: ${formatBytes(memory.usedBytes)}\nTotal: ${formatBytes(memory.totalBytes)}`
    : "Memory unavailable"
  readonly property string diskHoverText: metricAvailable(disk)
    ? `Mount: ${disk.mount}\nUsed: ${formatBytes(disk.usedBytes)}\nAvailable: ${formatBytes(disk.availableBytes)}`
    : "Disk unavailable"
  readonly property string temperatureHoverText: metricAvailable(temperature)
    ? `Sensor: ${temperature.name || "unavailable"}\nLabel: ${temperature.label || "unavailable"}`
    : "Temperature unavailable"

  property var __cpuPrevious: null
  property int __cpuFailures: 0
  property int __memoryFailures: 0
  property int __thermalFailures: 0
  property int __diskFailures: 0

  function metricConfigured(name) {
    const bar = ConfigService.config.bar;
    return bar.enabled && bar.metrics[name] && bar.metrics.order.indexOf(name) !== -1;
  }

  function metricAvailable(state) {
    return state.availability === "available" || state.availability === "degraded";
  }

  function statusText(status) {
    return status.length > 0 ? status[0].toUpperCase() + status.slice(1) : "Unknown";
  }

  function formatBytes(bytes) {
    if (!Number.isFinite(bytes) || bytes < 0) return "unavailable";
    const units = ["B", "KiB", "MiB", "GiB", "TiB"];
    let value = bytes;
    let unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    const formatted = value >= 10 || unit === 0 ? Math.round(value).toString() : value.toFixed(1);
    return `${formatted} ${units[unit]}`;
  }

  function consumedStates() {
    const states = [];
    if (cpuConsumer) states.push(cpu);
    if (memoryConsumer) states.push(memory);
    if (diskConsumer) states.push(disk);
    if (temperatureConsumer) states.push(temperature);
    return states;
  }

  function aggregateAvailability() {
    const states = consumedStates();
    if (states.length === 0) return "unavailable";
    if (states.every(state => state.availability === "available")) return "available";
    if (states.every(state => state.availability === "unavailable")) return "unavailable";
    if (states.some(state => state.availability === "unknown")) return "unknown";
    return "degraded";
  }

  function aggregateFreshness() {
    const states = consumedStates();
    if (states.some(state => state.freshness === "stale")) return "stale";
    if (states.length === 0 || states.some(state => state.freshness === "unknown")) return "unknown";
    return "current";
  }

  function latestUpdate() {
    const updates = consumedStates().map(state => state.lastUpdated).filter(value => value !== null);
    if (updates.length === 0) return null;
    return new Date(Math.max(...updates.map(value => value.getTime())));
  }

  function makeState(value, label) {
    return {
      value: value,
      label: label || "",
      availability: "unknown",
      freshness: "unknown",
      lastUpdated: null,
      lastError: null
    };
  }

  function freshState(base, value, extra) {
    const next = Object.assign({}, base, extra || {}, {
      value: value,
      availability: "available",
      freshness: "current",
      lastUpdated: new Date(),
      lastError: null
    });
    return next;
  }

  function staleState(base, error, thresholdReached) {
    const next = Object.assign({}, base, {
      availability: base.availability === "available"
        ? "degraded"
        : (thresholdReached ? "unavailable" : base.availability),
      freshness: thresholdReached ? "stale" : base.freshness,
      lastError: error || base.lastError
    });
    return next;
  }

  function reportError(code, summary, detail) {
    return DiagnosticsService.report(code, "system-metrics", summary, detail, true, null);
  }

  function handleCpuRead(text, failed, detail) {
    if (failed) {
      __cpuPrevious = null;
      __cpuFailures++;
      const error = reportError("METRICS_CPU_READ_FAILED", "Failed to read /proc/stat", detail);
      cpu = staleState(cpu, error, __cpuFailures >= 2);
      return;
    }
    const result = SystemMetrics.parseCpuStat(text, __cpuPrevious);
    if (!result.ok) {
      __cpuPrevious = null;
      __cpuFailures++;
      const error = reportError("METRICS_CPU_PARSE_FAILED", "Failed to parse /proc/stat", result.error);
      cpu = staleState(cpu, error, __cpuFailures >= 2);
      return;
    }
    __cpuPrevious = { total: result.total, idle: result.idle };
    if (result.usagePercent === null) {
      __cpuFailures = 0;
      return;
    }
    __cpuFailures = 0;
    cpu = freshState(cpu, result.usagePercent);
  }

  function handleMemRead(text, failed, detail) {
    if (failed) {
      __memoryFailures++;
      const error = reportError("METRICS_MEMORY_READ_FAILED", "Failed to read /proc/meminfo", detail);
      memory = staleState(memory, error, __memoryFailures >= 2);
      return;
    }
    const result = SystemMetrics.parseMemInfo(text);
    if (!result.ok) {
      __memoryFailures++;
      const error = reportError("METRICS_MEMORY_PARSE_FAILED", "Failed to parse /proc/meminfo", result.error);
      memory = staleState(memory, error, __memoryFailures >= 2);
      return;
    }
    __memoryFailures = 0;
    memory = freshState(memory, result.usedPercent, {
      usedBytes: result.usedKb * 1024,
      totalBytes: result.totalKb * 1024
    });
  }

  function handleThermalRead(result) {
    if (!result.ok) {
      __thermalFailures++;
      if (__thermalFailures >= 3) helperAdapter.thermalSensorPath = "";
      const error = reportError("METRICS_THERMAL_HELPER_FAILED", "Thermal helper failed", result.error);
      temperature = staleState(temperature, error, __thermalFailures >= 3);
      return;
    }
    const parsed = SystemMetrics.parseThermalOutput(JSON.stringify(result.data));
    if (!parsed.ok) {
      __thermalFailures++;
      const error = reportError("METRICS_THERMAL_PARSE_FAILED", "Failed to parse thermal JSON", parsed.error);
      temperature = staleState(temperature, error, __thermalFailures >= 3);
      return;
    }
    const selected = SystemMetrics.selectThermalSensor(parsed.sensors);
    if (!selected) {
      __thermalFailures++;
      if (__thermalFailures >= 3) helperAdapter.thermalSensorPath = "";
      const error = reportError("METRICS_THERMAL_NONE_FOUND", "No usable thermal sensor discovered", "");
      temperature = staleState(temperature, error, __thermalFailures >= 3);
      return;
    }
    __thermalFailures = 0;
    helperAdapter.thermalSensorPath = selected.path;
    temperature = freshState(temperature, Math.round(selected.temp / 1000), {
      label: selected.label,
      name: selected.name,
      path: selected.path
    });
  }

  function handleDiskRead(result) {
    if (!result.ok) {
      __diskFailures++;
      const error = reportError("METRICS_DISK_HELPER_FAILED", "Disk helper failed", result.error);
      disk = staleState(disk, error, __diskFailures >= 3);
      return;
    }
    const parsed = SystemMetrics.parseDiskOutput(JSON.stringify(result.data));
    if (!parsed.ok) {
      __diskFailures++;
      const error = reportError("METRICS_DISK_PARSE_FAILED", "Failed to parse disk JSON", parsed.error);
      disk = staleState(disk, error, __diskFailures >= 3);
      return;
    }
    const selected = SystemMetrics.selectRootDisk(parsed.disks);
    if (!selected) {
      __diskFailures++;
      const error = reportError("METRICS_DISK_NONE_FOUND", "Root mount not found in disk output", "");
      disk = staleState(disk, error, __diskFailures >= 3);
      return;
    }
    __diskFailures = 0;
    disk = freshState(disk, selected.percent, {
      mount: selected.mount,
      usedBytes: Number(selected.used),
      availableBytes: Number(selected.available)
    });
  }

  function updateAdapters() {
    if (procAdapter) {
      procAdapter.cpuActive = cpuConsumer;
      procAdapter.memoryActive = memoryConsumer;
    }
    if (helperAdapter) {
      helperAdapter.thermalActive = temperatureConsumer;
      helperAdapter.diskActive = diskConsumer;
    }
  }

  Connections {
    target: root.procAdapter
    function onCpuRead(text, failed, error) { root.handleCpuRead(text, failed, error); }
    function onMemRead(text, failed, error) { root.handleMemRead(text, failed, error); }
  }

  Connections {
    target: root.helperAdapter
    function onThermalRead(result) { root.handleThermalRead(result); }
    function onDiskRead(result) { root.handleDiskRead(result); }
  }

  Integrations.SystemMetricsProcAdapter { id: realProcAdapter }
  Integrations.SystemMetricsHelperAdapter { id: realHelperAdapter }

  onCpuConsumerChanged: updateAdapters()
  onMemoryConsumerChanged: updateAdapters()
  onDiskConsumerChanged: updateAdapters()
  onTemperatureConsumerChanged: updateAdapters()
  onProcAdapterChanged: updateAdapters()
  onHelperAdapterChanged: updateAdapters()

  Component.onCompleted: updateAdapters()
}
