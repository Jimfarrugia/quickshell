# ADR-033: Shared dashboard shell and source-module routing

Status: Accepted by user on 2026-09-02

Decision: QE dashboards use one overlay layer-shell shell with one active
dashboard slot. The shell follows the bar edge, derives its horizontal corner
from the source module, uses a 20px gap from the bar and opposite screen edge,
and grows until bounded screen height before scrolling its content. Its initial
width is 1.5 times the Sidebar's total outer width, with 20px content insets.
Feature content remains owned by domain services; dashboard IPC uses the
namespaced `open`, `close`, `toggle`, and `isOpen` contract, and launcher entries
are built-in curated QE actions.

Context: audio, Bluetooth, and network dashboards need a common transient
surface without prematurely coupling their feature content or the future
control center. Source-module placement keeps a dashboard next to the control
that opened it, while a single slot prevents overlapping surfaces.

Consequences: Phase 8 establishes the shared shell and audio dashboard. Audio's
unsupported routing remains available through the clickable `settings` icon,
which opens `pavucontrol`; the help catalog remains display-only. Top-docked
bars use the mirrored below-bar relationship, and missing services or fallback
launch failures remain visible as local degraded states.
