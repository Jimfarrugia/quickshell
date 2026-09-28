import QtQuick
import Quickshell
import "services" as Services
import "modules/bar" as Bar

ShellRoot {
  id: root

  Bar.CpuModule { id: cpuModule }
  Bar.TemperatureModule { id: temperatureModule }

  function fail(message) {
    console.error(`METRIC_BAR_MODULE_TEST_FAILED: ${message}`);
    Qt.quit();
  }

  function tokens() {
    return Services.ThemeService.theme.tokens;
  }

  function setCpu(value, availability, freshness) {
    Services.SystemMetricsService.cpu = {
      value: value,
      availability: availability,
      freshness: freshness,
      lastUpdated: null,
      lastError: null
    };
  }

  function setTemperature(value, availability, freshness) {
    Services.SystemMetricsService.temperature = {
      value: value,
      availability: availability,
      freshness: freshness,
      lastUpdated: null,
      lastError: null
    };
  }

  function runChecks() {
    const theme = tokens();

    // Unknown state: loading placeholder, no warning, neutral indicator.
    setCpu(0, "unknown", "unknown");
    if (cpuModule.text !== "CPU...")
      return fail(`unknown cpu rendered '${cpuModule.text}'`);
    if (cpuModule.warning)
      return fail("unknown cpu raised a warning");
    if (cpuModule.iconColor.toString() !== theme.on_surface_indicator.toString())
      return fail("unknown cpu did not use the neutral indicator colour");

    // Available, below threshold: value + unit, subdued text.
    setCpu(50, "available", "current");
    if (cpuModule.text !== "50%")
      return fail(`available cpu rendered '${cpuModule.text}'`);
    if (cpuModule.warning)
      return fail("healthy cpu raised a warning");
    if (cpuModule.iconColor.toString() !== theme.on_surface_indicator.toString())
      return fail("healthy cpu icon was not the neutral indicator colour");
    if (cpuModule.textColor.toString() !== theme.on_surface_subdued.toString())
      return fail("healthy cpu text was not subdued");
    if (cpuModule.hoverText.indexOf("Usage") === -1)
      return fail("available cpu did not expose the usage hover text");

    // Warn threshold is exclusive: 80 stays neutral, 81 warns.
    setCpu(80, "available", "current");
    if (cpuModule.iconColor.toString() !== theme.on_surface_indicator.toString())
      return fail("cpu at the warn threshold was escalated too early");
    setCpu(81, "available", "current");
    if (cpuModule.iconColor.toString() !== theme.warning.toString())
      return fail("cpu above the warn threshold did not use the warning colour");

    // Critical threshold escalates to error.
    setCpu(95, "available", "current");
    if (cpuModule.iconColor.toString() !== theme.error.toString())
      return fail("cpu above the critical threshold did not use the error colour");
    if (cpuModule.textColor.toString() !== theme.error.toString())
      return fail("critical cpu text did not use the error colour");

    // Stale content warns without escalating to error.
    setCpu(50, "available", "stale");
    if (!cpuModule.warning)
      return fail("stale cpu did not raise a warning");
    if (cpuModule.iconColor.toString() !== theme.warning.toString())
      return fail("stale cpu did not use the warning colour");

    // Unavailable: "CPU!" and error colour.
    setCpu(0, "unavailable", "unknown");
    if (cpuModule.text !== "CPU!")
      return fail(`unavailable cpu rendered '${cpuModule.text}'`);
    if (cpuModule.iconColor.toString() !== theme.error.toString())
      return fail("unavailable cpu did not use the error colour");

    // Deskewed thresholds and unit: temperature warns above 70 and shows °C.
    setTemperature(75, "available", "current");
    if (temperatureModule.text !== "75°C")
      return fail(`temperature rendered '${temperatureModule.text}'`);
    if (temperatureModule.iconColor.toString() !== theme.warning.toString())
      return fail("temperature above its warn threshold did not use the warning colour");
    setTemperature(85, "available", "current");
    if (temperatureModule.iconColor.toString() !== theme.error.toString())
      return fail("temperature above its critical threshold did not use the error colour");
    setTemperature(0, "unavailable", "unknown");
    if (temperatureModule.text !== "Temp!")
      return fail(`unavailable temperature rendered '${temperatureModule.text}'`);

    console.log("METRIC_BAR_MODULE_TEST_PASSED");
    Qt.quit();
  }

  // Stop the live /proc pollers so injected metric state is not overwritten.
  function disableMetrics() {
    Services.ConfigService.applyText(JSON.stringify({
      schemaVersion: 1,
      bar: {
        enabled: true,
        metrics: { cpu: false, memory: false, disk: false, temperature: false, order: [] }
      }
    }));
  }

  Timer {
    id: configTimer
    interval: 50
    repeat: true
    running: true
    onTriggered: {
      if (!Services.ConfigService.hasLoaded) return;
      running = false;
      root.disableMetrics();
      settleTimer.restart();
    }
  }

  Timer {
    id: settleTimer
    interval: 60
    repeat: false
    onTriggered: root.runChecks()
  }

  Timer {
    interval: 4000
    running: true
    onTriggered: root.fail("test timed out")
  }
}
