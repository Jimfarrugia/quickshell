import QtQuick
import "../../services" as Services

Row {
  spacing: Services.ConfigService.config.bar.moduleSpacing

  Repeater {
    model: Services.ConfigService.config.bar.metrics.order

    delegate: Loader {
      required property var modelData

      source: {
        switch (modelData) {
        case "cpu": return "CpuModule.qml";
        case "memory": return "MemoryModule.qml";
        case "disk": return "DiskModule.qml";
        case "temperature": return "TemperatureModule.qml";
        default: return "";
        }
      }
    }
  }
}
