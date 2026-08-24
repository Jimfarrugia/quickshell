import QtQuick
import Quickshell
import "services" as Services
import "modules/bar" as Bar
import "tests/fixtures/qml" as Fixtures

ShellRoot {
  id: root

  Fixtures.FakeSystemMetricsProcAdapter { id: fakeProc }
  Fixtures.FakeSystemMetricsHelperAdapter { id: fakeHelper }
  Bar.CpuModule { id: cpuModule }
  Bar.MemoryModule { id: memoryModule }
  Bar.DiskModule { id: diskModule }
  Bar.TemperatureModule { id: temperatureModule }

  function fail(message) {
    console.error(`PHASE3_SERVICE_TEST_FAILED: ${message}`);
    Qt.quit();
  }

  function setupFakes() {
    Services.SystemMetricsService.procAdapter.cpuActive = false;
    Services.SystemMetricsService.procAdapter.memoryActive = false;
    Services.SystemMetricsService.procAdapter = fakeProc;
    Services.SystemMetricsService.helperAdapter.thermalActive = false;
    Services.SystemMetricsService.helperAdapter.diskActive = false;
    Services.SystemMetricsService.helperAdapter = fakeHelper;
    Services.SystemMetricsService.updateAdapters();
  }

  function runChecks() {
    if (!Services.ConfigService.hasLoaded) {
      retryTimer.restart();
      return;
    }

    setupFakes();

    if (!Services.SystemMetricsService.hasConsumer)
      return fail("metrics should have a consumer with default config");
    if (!fakeProc.active || !fakeHelper.active)
      return fail("adapters did not activate for a consumer");
    if (!fakeProc.cpuActive || !fakeProc.memoryActive || !fakeHelper.thermalActive || !fakeHelper.diskActive)
      return fail("per-metric consumers did not activate");

    // CPU: two samples to produce a known usage value.
    fakeProc.emitCpu("cpu 100 0 0 900 0 0 0 0 0 0", false, "");
    fakeProc.emitCpu("cpu 200 0 0 900 0 0 0 0 0 0", false, "");
    if (Services.SystemMetricsService.cpu.value !== 100)
      return fail(`cpu usage was ${Services.SystemMetricsService.cpu.value}, expected 100`);
    if (Services.SystemMetricsService.cpu.freshness !== "current")
      return fail("cpu was not marked current after success");
    if (cpuModule.hoverText !== "Usage: 100%\nSource: /proc/stat\nStatus: Current")
      return fail(`CPU hover was '${cpuModule.hoverText}'`);

    // Memory: known used percent.
    fakeProc.emitMem("MemTotal: 1000 kB\nMemAvailable: 250 kB\n", false, "");
    if (Services.SystemMetricsService.memory.value !== 75)
      return fail(`memory usage was ${Services.SystemMetricsService.memory.value}, expected 75`);
    if (memoryModule.hoverText !== "Used: 750 KiB\nTotal: 1000 KiB")
      return fail(`memory hover was '${memoryModule.hoverText}'`);

    // Temperature.
    fakeHelper.emitThermal({ ok: true, data: { schemaVersion: 1, sensors: [{ name: "k10temp", label: "Tctl", path: "/sys/test", temp: 42850 }] } });
    if (Services.SystemMetricsService.temperature.value !== 43)
      return fail(`temperature was ${Services.SystemMetricsService.temperature.value}, expected 43`);
    if (Services.SystemMetricsService.temperature.label !== "Tctl")
      return fail("thermal label was not preserved");
    if (fakeHelper.thermalSensorPath !== "/sys/test")
      return fail("selected thermal sensor was not retained");
    if (temperatureModule.hoverText !== "Sensor: k10temp\nLabel: Tctl")
      return fail(`temperature hover was '${temperatureModule.hoverText}'`);
    Services.SystemMetricsService.temperature = Object.assign({}, Services.SystemMetricsService.temperature, { value: 71 });
    if (temperatureModule.icon !== "thermostat")
      return fail("temperature module did not retain the thermostat icon above 70");
    if (temperatureModule.iconColor.toString() !== Services.ThemeService.theme.tokens.warning.toString()
        || temperatureModule.textColor.toString() !== Services.ThemeService.theme.tokens.warning.toString())
      return fail("temperature above 70 did not use the warning color");
    Services.SystemMetricsService.temperature = Object.assign({}, Services.SystemMetricsService.temperature, { value: 81 });
    if (temperatureModule.iconColor.toString() !== Services.ThemeService.theme.tokens.error.toString()
        || temperatureModule.textColor.toString() !== Services.ThemeService.theme.tokens.error.toString())
      return fail("temperature above 80 did not use the error color");
    Services.SystemMetricsService.temperature = Object.assign({}, Services.SystemMetricsService.temperature, { value: 43 });

    // Disk.
    fakeHelper.emitDisk({ ok: true, data: { schemaVersion: 1, disks: [{ filesystem: "/dev/root", size: "100", used: "40", available: "60", mount: "/", percent: 40 }] } });
    if (Services.SystemMetricsService.disk.value !== 40)
      return fail(`disk usage was ${Services.SystemMetricsService.disk.value}, expected 40`);
    if (diskModule.hoverText !== "Mount: /\nUsed: 40 B\nAvailable: 60 B")
      return fail(`disk hover was '${diskModule.hoverText}'`);

    // CPU stale after two failures; value retained.
    fakeProc.emitCpu("", true, "fail");
    if (Services.SystemMetricsService.cpu.freshness !== "current")
      return fail("cpu freshness should remain current after first failure");
    fakeProc.emitCpu("", true, "fail");
    if (Services.SystemMetricsService.cpu.freshness !== "stale")
      return fail("cpu was not marked stale after second failure");
    if (Services.SystemMetricsService.cpu.value !== 100)
      return fail("cpu value was not retained when stale");

    // Recovery.
    fakeProc.emitCpu("cpu 300 0 0 900 0 0 0 0 0 0", false, "");
    if (Services.SystemMetricsService.cpu.freshness !== "stale")
      return fail("first CPU recovery sample should establish a new baseline");
    fakeProc.emitCpu("cpu 400 0 0 900 0 0 0 0 0 0", false, "");
    if (Services.SystemMetricsService.cpu.freshness !== "current")
      return fail("cpu did not recover to current");

    // Temperature stale after three failures.
    fakeHelper.emitThermal({ ok: false, error: "x" });
    fakeHelper.emitThermal({ ok: false, error: "x" });
    if (Services.SystemMetricsService.temperature.freshness === "stale")
      return fail("temperature became stale before three failures");
    fakeHelper.emitThermal({ ok: false, error: "x" });
    if (Services.SystemMetricsService.temperature.freshness !== "stale")
      return fail("temperature was not marked stale after three failures");
    if (fakeHelper.thermalSensorPath !== "")
      return fail("failed thermal sensor was not cleared for rediscovery");

    // Consumer lifecycle: disabling all metrics stops adapters.
    const disabled = JSON.stringify({
      schemaVersion: 1,
      bar: {
        enabled: true,
        metrics: { cpu: false, memory: false, disk: false, temperature: false, order: [] }
      }
    });
    Services.ConfigService.applyText(disabled);
    if (Services.SystemMetricsService.hasConsumer)
      return fail("disabling all metrics should remove the consumer");
    if (fakeProc.active || fakeHelper.active)
      return fail("adapters should stop when there is no consumer");

    const cpuOnly = JSON.stringify({
      schemaVersion: 1,
      bar: {
        enabled: true,
        metrics: { cpu: true, memory: false, disk: false, temperature: false, order: ["cpu"] }
      }
    });
    Services.ConfigService.applyText(cpuOnly);
    if (!fakeProc.cpuActive || fakeProc.memoryActive || fakeHelper.active)
      return fail("CPU-only config should not poll memory, thermal, or disk");

    const mismatched = JSON.stringify({
      schemaVersion: 1,
      bar: {
        enabled: true,
        metrics: { cpu: true, memory: false, disk: false, temperature: false, order: ["memory"] }
      }
    });
    Services.ConfigService.applyText(mismatched);
    if (Services.ConfigService.validationErrors.length === 0
        || Services.ConfigService.config.bar.metrics.order.length !== 1
        || Services.ConfigService.config.bar.metrics.order[0] !== "cpu")
      return fail("enable/order mismatch did not fall back to the enabled metric set");

    console.log("PHASE3_SERVICE_TEST_PASSED");
    Qt.quit();
  }

  Timer {
    id: retryTimer
    interval: 50
    repeat: false
    onTriggered: root.runChecks()
  }

  Timer {
    interval: 4000
    running: true
    onTriggered: root.fail("test timed out")
  }

  Component.onCompleted: Qt.callLater(runChecks)
}
