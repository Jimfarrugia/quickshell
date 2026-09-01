# Shared dashboard surface foundation

Status: Accepted by user on 2026-09-02

QE dashboards use one overlay layer-shell dashboard shell with a single active
dashboard slot. The shell follows the bar edge, derives its horizontal corner
from the source module, grows within 20px screen/bar bounds, and uses a
content-scrolling interior when height is exhausted. This preserves a common
surface contract for audio, Bluetooth, and network while keeping feature state
in domain services and unsupported operations in their existing fallback tools.
