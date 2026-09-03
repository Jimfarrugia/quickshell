# QE Architecture Decision Log

Status: Authoritative accepted-decision record

This document is the authoritative log of QE architectural decisions and their
recorded rationale. `docs/ARCHITECTURE.md` remains authoritative for the current
architecture, while `docs/PLAN.md` remains authoritative for roadmap, status,
active/future phases, risks, and planning sequence.

Agents should not read this entire file by default. Read ADRs explicitly
referenced by the active phase or task, plus any ADR whose affected area overlaps
a proposed architectural change.

Historical age does not make an ADR non-authoritative. An accepted decision
remains in this log unless it is explicitly superseded or revised through the
planning-change procedure.

## Identifier integrity note

The source plan contained two different accepted records numbered `ADR-022`:
**Project-owned authored defaults bundle** and **QE-generated Yazi wallpaper
flavor**. After a repository-wide reference audit, the user explicitly resolved
the collision by retaining `ADR-022` for the earlier authored-defaults decision
and assigning `ADR-028` to the later Yazi decision.

Documentation maintenance must never renumber, merge, delete, or reinterpret an
accepted ADR merely to tidy the sequence.

## Decision Index

| ADR | Decision | Status |
| --- | --- | --- |
| ADR-001 | Layered QE platform | Accepted |
| ADR-002 | Separate lock process | Accepted by user |
| ADR-003 | JSON configuration and themes | Accepted by user |
| ADR-004 | Independent QE and external theme scopes | Accepted by user |
| ADR-005 | QE-first, external-best-effort theme apply | Accepted by user |
| ADR-006 | Matugen generates QE and external `Wallpaper` outputs | Accepted by user |
| ADR-007 | Process-session notification history | Accepted by user |
| ADR-008 | Staged Dunst cutover | Accepted by user |
| ADR-009 | Bar as first vertical slice | Accepted by user |
| ADR-010 | Defer production supervision | Accepted by user |
| ADR-011 | Native integration before commands | Accepted architectural rule |
| ADR-012 | Add charging semantic token before release | Accepted by user |
| ADR-013 | Idle inhibition exposes requested state only | Accepted by user on 2026-08-24 |
| ADR-014 | Add tooltip semantic token before release | Accepted by user on 2026-08-24 |
| ADR-015 | Adopt Matugen-style paired semantic roles before release | Accepted by user on 2026-08-25 |
| ADR-016 | Use separate namespaced IPC targets for transient surfaces | Accepted by user on 2026-08-25 |
| ADR-017 | Keep external operation identity at the QE adapter boundary | Accepted as part of the approved Phase 4 machine contract on 2026-08-25 |
| ADR-018 | Stage QE wallpaper themes before promotion | Accepted as part of the Phase 4 wallpaper implementation on 2026-08-25 |
| ADR-019 | QE-generated external wallpaper theme slots | Not explicitly stated in source record |
| ADR-020 | Apply-time focused Kitty bar compositing | Not explicitly stated in source record |
| ADR-022 | Project-owned authored defaults bundle | Accepted by user |
| ADR-021 | Vim-style selector navigation convention | Accepted by user |
| ADR-028 | QE-generated Yazi wallpaper flavor | Accepted by user |
| ADR-023 | QE-generated imv and mpv wallpaper slots | Accepted by user |
| ADR-024 | Isolated QE notification ownership prototype | Accepted by user on 2026-08-29 |
| ADR-025 | QE-owned OSD and reversible action cutover | Accepted for Phase 6 implementation |
| ADR-026 | Notification center as a layer-shell sidebar | Accepted by user on 2026-08-30 |
| ADR-027 | Dedicated sidebar surface token | Accepted by user on 2026-08-30 |
| ADR-032 | Add low surface semantic token | Accepted by user on 2026-09-01 |
| ADR-033 | Shared dashboard shell and source-module routing | Accepted by user on 2026-09-02 |
| ADR-034 | Network dashboard v1 boundary | Accepted by user on 2026-09-03 |

## ADR-032: Add low surface semantic token

Status: Accepted by user on 2026-09-01

Decision: add required theme token `surface_low`, mapped to the same resolved
color as `surface_sidebar` in every authored, generated, and fallback theme.

Context: consumers need a semantic low-surface role while preserving the
existing sidebar color mapping and theme-specific palette ownership.

Consequences: the theme-v1 contract expands from 33 to 34 roles. Validators,
schemas, fixtures, fallbacks, and Matugen-generated themes must provide the
token together.

## ADR-033: Shared dashboard shell and source-module routing

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

## ADR-034: Network dashboard v1 boundary

Status: Accepted by user on 2026-09-03

Decision: Phase 10 manages personal Wi-Fi through Quickshell's native
NetworkManager API: open and PSK connections, radio enable/disable,
connect/disconnect/forget, and inline selection of distinct saved profiles.
Wired networking is read-only; enterprise/EAP, VPN, proxy, hidden-network
creation, arbitrary profile editing, and unsupported authentication remain in
`nm-connection-editor`. A retry PSK may update a NetworkManager-owned saved
profile, but QE never persists or logs the credential. Because Quickshell 0.3.1
exposes no default-route device, QE uses a deterministic connected-device
priority rather than adding an `nmcli` or new DBus adapter solely for device
selection.

Consequences: the dashboard uses one active-device presentation, scans only
while open with an explicit refresh action, serializes mutations, and treats
only same-target newer intent as superseding. NetworkManager loss, stale data,
timeouts, and failures remain explicit and preserve confirmed state.

## ADR-001: Layered QE platform

Status: Accepted

Decision: use presentation/modules -> domain services -> integration adapters ->
external systems as the dependency direction.

Context: QE spans many shared stateful integrations and must not become a
collection of QML views that each spawn commands.

Rationale: centralizes state ownership and lifecycle while retaining declarative
presentation and replaceable external boundaries.

Alternatives considered: monolithic QML; independent feature applications;
framework-heavy abstraction layers.

Consequences: more explicit interfaces and fixtures are required; trivial local
view state remains local to avoid unnecessary services.

Affected areas: all modules and integrations.

Revisit if: Quickshell imposes a verified lifecycle limitation that prevents a
domain service from safely owning a required object.

## ADR-002: Separate lock process

Status: Accepted by user

Decision: persistent shell and secure lock use separate Quickshell processes.

Context: lock security and availability should not share the persistent shell's
large failure domain.

Rationale: minimizes lock dependencies and prevents bar/dashboard failures from
affecting the lock UI.

Alternatives considered: one process; additional process isolation for all
transient tools.

Consequences: theme/config sharing occurs through validated disk state; a crash
after secure lock remains fail-closed and requires session recovery.

Affected areas: entry points, theme/config readers, lock lifecycle, Hypridle.

Revisit if: the compositor/session-lock protocol gains a verified secure
handover/recovery mechanism or process separation causes a security regression.

## ADR-003: JSON configuration and themes

Status: Accepted by user

Decision: use strict, versioned JSON for user configuration and themes.

Context: QE and external generators need a portable, schema-validatable format.

Rationale: Quickshell supports JSON adapters and external tools can reliably
produce/validate JSON.

Alternatives considered: executable QML config, JSONC, TOML.

Consequences: comments are unavailable; schemas and diagnostics must make files
understandable. Generated and authored JSON remain in separate roots.

Affected areas: config, themes, Matugen, persistent state.

Revisit if: native tooling cannot provide safe transactional JSON reload or user
maintenance proves materially worse than alternatives.

## ADR-004: Independent QE and external theme scopes

Status: Accepted by user

Decision: QE and external applications each own their active theme. QE selection
automatically requests the same external ID after QE commits.

Context: the user intentionally permits independent themes and wants QE to
remain successful when external targets fail.

Rationale: reflects actual non-transactional application behavior and permits
external CLI use without QE dependence.

Alternatives considered: external switcher globally authoritative; QE globally
authoritative; neutral shared global state.

Consequences: visual drift is valid and must be visible in status. Values are
not synchronized bidirectionally.

Affected areas: ThemeService, external switcher, selector UI, diagnostics.

Revisit if: the user later requires globally locked theme consistency.

## ADR-005: QE-first, external-best-effort theme apply

Status: Accepted by user

Decision: validate/persist/publish QE first; abort on QE failure; otherwise run
the external apply and report its independent result without QE rollback.

Context: external targets cannot provide a reliable global transaction or
rollback.

Rationale: preserves responsive, truthful QE behavior and avoids making a local
theme dependent on every installed application.

Alternatives considered: rollback all possible; external apply despite QE
failure; declare success only if every target succeeds.

Consequences: partial external drift persists and requires target-level retry.

Affected areas: ThemeService, switcher contract, UI status.

Revisit if: external targets acquire transactional staging and rollback.

## ADR-006: Matugen generates QE and external `Wallpaper` outputs

Status: Accepted by user

Decision: one wallpaper input generates a QE theme conforming to the normal
schema and supported external application artifacts.

Context: `Wallpaper` must be selectable like a manual QE theme and participate
in wider desktop theming.

Rationale: one derivation pipeline avoids manually maintaining unrelated
generated palettes.

Alternatives considered: QE-only generation; limited core-app generation.

Consequences: template validation and staged promotion become critical; target
coverage can vary but must be reported.

Affected areas: Matugen config, theme schema, external switcher, wallpaper flow.

Revisit if: maintaining broad external templates becomes disproportionate; a
documented supported-target subset may then replace universal generation.

## ADR-007: Process-session notification history

Status: Accepted by user

Decision: do not persist notification history to disk initially.

Context: disk persistence adds privacy, retention, serialization, and migration
requirements.

Rationale: current-process history meets the initial notification-center goal
with lower risk.

Alternatives considered: persistence from first release; popups without history.

Consequences: history is lost on QE restart and diagnostics must not imply
otherwise.

Affected areas: NotificationService and center.

Revisit if: daily use demonstrates restart-persistent history is valuable enough
to justify a privacy and migration design.

## ADR-008: Staged Dunst cutover

Status: Accepted by user

Decision: keep Dunst during development; test QE ownership only in isolated
windows/sessions; disable Dunst only after notification acceptance passes.

Context: the DBus notification service has exclusive ownership.

Rationale: preserves reliable daily notifications and a simple rollback.

Alternatives considered: replace Dunst early; defer notification work entirely.

Consequences: notification development needs explicit owner transitions and
cannot be casually tested alongside Dunst.

Affected areas: Phase 5-6, Dunst user service, hardware scripts.

Revisit if: DBus activation prevents reliable isolated testing; use a separate
test user/session instead.

## ADR-009: Bar as first vertical slice

Status: Accepted by user

Decision: validate foundations through a safely coexisting bar.

Context: the bar exercises multiple native event-driven integrations and daily
presentation without exclusive protocol ownership.

Rationale: high architectural coverage with lower migration risk than lock or
notifications.

Alternatives considered: theme selector, launcher, lock.

Consequences: first slice intentionally omits feature breadth and cutover.

Affected areas: Phases 1-3.

Revisit if: Waybar coexistence proves technically unsafe; use a test floating
surface with the same service contracts.

## ADR-010: Defer production supervision

Status: Accepted by user

Decision: do not choose systemd user service or Hyprland autostart until runtime
behavior is known.

Context: restart policy, environment import, and failure handling depend on the
mature process topology.

Rationale: avoids encoding lifecycle assumptions before the shell is stable.

Alternatives considered: systemd user service immediately; Hyprland autostart
immediately.

Consequences: development uses explicit launch commands; Phase 13 must make and
record the production decision.

Affected areas: entry points, diagnostics, deployment.

Revisit if: an earlier cutover requires automatic session startup.

## ADR-011: Native integration before commands

Status: Accepted architectural rule

Decision: use installed Quickshell native APIs for Hyprland, PipeWire,
NetworkManager, BlueZ, UPower, MPRIS, tray, notifications, PAM, session lock,
desktop entries, and idle inhibition. Use commands only for uncovered behavior.

Context: current scripts parse human output and scatter lifecycle behavior.

Rationale: native APIs provide event-driven state, object lifetime, and safer
operations.

Alternatives considered: retain command wrappers for all integrations.

Consequences: adapters must handle native object invalidation and version
differences. Brightness remains a command boundary in 0.3.0.

Affected areas: all system services.

Revisit if: a native API is demonstrably incomplete or unstable for a required
operation; document the exact fallback contract.

## ADR-012: Add charging semantic token before release

Status: Accepted by user

Decision: revise the pre-release theme-v1 contract to require a `charging`
semantic color token.

Context: charging is a distinct visible power state and should not implicitly
reuse warning or accent semantics. QE has no shipped external theme consumers,
so a coordinated v1 revision is smaller and safer than adding schema migration
code now.

Rationale: every authored theme can choose an intentional charging color while
bar presentation remains palette-independent.

Alternatives considered: reuse `warning`; reuse `accentSecondary`; introduce
theme schema v2 immediately.

Consequences: all authored themes, fixtures, emergency fallback data, runtime
validation, JSON Schema, and token documentation require `charging`. Poimandres
maps it to `palette.yellow`; Gruvbox maps it to `palette.yellowLight`.

Affected areas: theme-v1 contract, Phase 2 power presentation, future generated
themes.

Revisit if: external theme consumers ship before another token change; further
contract changes then require a versioned migration.

## ADR-013: Idle inhibition exposes requested state only

Status: Accepted by user on 2026-08-24

Decision: implement the Phase 3 native Wayland idle-inhibitor toggle as
process-session requested state bound to a persistent QE bar window. Do not
claim or synthesize compositor-confirmed active state.

Context: installed Quickshell 0.3.0 exposes `IdleInhibitor.enabled` and `window`
but no active property, protocol-object status, rejection signal, or compositor
acknowledgement. Treating `enabled` as confirmed would violate QE's
requested-versus-confirmed state rule.

Rationale: requested-only state preserves the native no-command boundary and
honestly represents what QE can know. The Wayland object lifetime still gives
safe automatic release when the window or process disappears.

Alternatives considered: defer the module entirely; add a C++ native extension
in Phase 3; present `enabled` as confirmed active.

Consequences: the bar indicates that inhibition is requested, not guaranteed;
confirmed-active reporting remains deferred. The request is not persisted and
does not replace Hypridle, manual locking, or suspend policy.

Affected areas: `IdleService`, bar idle-inhibitor presentation, Phase 3
acceptance language, later control-center idle state.

Revisit if: Quickshell exposes reliable inhibitor status or QE adopts a reviewed
native extension that can distinguish protocol creation/revocation.

## ADR-014: Add tooltip semantic token before release

Status: Accepted by user on 2026-08-24

Decision: revise the pre-release theme-v1 contract to require a `tooltip`
semantic color token. Poimandres maps it to the new `palette.black` value
`#171922`; Gruvbox maps it to `palette.blackLight`; the emergency theme provides
an internal dark fallback.

Context: bar hover popups need a deliberate background distinct from general
raised surfaces. Reusing `surfaceRaised` coupled tooltip styling to unrelated
module-hover and elevated-surface decisions.

Rationale: one semantic token lets each authored theme choose tooltip contrast
without presentation code knowing palette names.

Alternatives considered: continue using `surfaceRaised`; hard-code popup colors;
add a bar-specific tooltip color outside the theme contract.

Consequences: runtime validation, JSON Schema, emergency fallback, authored
themes, fixtures, and token documentation require `tooltip`. This remains a
pre-release schema-v1 revision with no shipped migration obligation.

Affected areas: theme schema and validation, `ThemeService`, authored themes,
bar tooltip presentation, fixtures, and future generated-theme mappings.

Revisit if: tooltip surfaces later require separate normal, border, and rich
content tokens.

## ADR-015: Adopt Matugen-style paired semantic roles before release

Status: Accepted by user on 2026-08-25

Decision: replace the provisional 15-token camelCase theme-v1 vocabulary with
the approved 32-role `snake_case` contract documented in the Phase 4 audit. Use
paired `on_*` foregrounds for authored surfaces and accents; distinct hover,
pressed, focus, disabled, placeholder, link, and highlight roles; existing QE
success, charging, warning, and error states; and shadow/scrim utilities.

Context: current presentation forced unrelated roles to share colors, including
selected text with a background token, disabled content with secondary active
text, inline hover with tooltip surfaces, and tooltip foreground with generic
text. Planned selectors, notifications, launcher, dashboards, and lock surfaces
would multiply those ambiguities. The user requested broader surface,
interaction, accessibility, link, and highlight coverage and Matugen's naming
style before the contract becomes a generator input.

Rationale: Matugen exposes `snake_case` Material roles and paired foregrounds,
so retaining that convention reduces template translation and makes contrast
relationships explicit. QE-specific roles remain only where the generated
scheme has no direct shell semantic. The contract is still pre-release and has
no shipped external consumers, making one coordinated revision safer than
compatibility aliases or an immediate schema v2.

Alternatives considered: retain the 15-token contract; the rejected 19-token
camelCase proposal; import every Matugen role without QE curation; add
component-specific notification, slider, dashboard, or lock tokens; add pending
and urgency status colors in this revision.

Consequences: runtime validation, JSON Schema, emergency fallback, authored
themes, fixtures, all existing consumers, tests, architecture documentation, and
future Matugen templates use the 32 names atomically. Authored and generated
surface/foreground pairs target 4.5:1 normal-text contrast and 3:1 for large
text, meaningful icons, focus, and boundaries. Theme identity is preserved, but
derived palette values are allowed where required for contrast. Pending intent
uses primary emphasis plus motion or text rather than warning or success.

Affected areas: theme-v1 contract, all QE presentation, manual theme conversion,
Matugen templates, selectors, notifications/OSDs, launcher/help, dashboards,
and the isolated lock theme reader.

Revisit if: implemented surfaces expose a semantic role that cannot be composed
from this vocabulary, or Matugen changes its stable generated-role contract.

## ADR-016: Use separate namespaced IPC targets for transient surfaces

Status: Accepted by user on 2026-08-25

Decision: use one module-owned `IpcHandler` target per transient surface, named
`qe-<surface>`, rather than one central `qe` handler. Expose consistent typed
`open`, `close`, `toggle`, and `isOpen` methods where applicable. Route requests
through `SurfaceService`, which owns requested visibility; let `shell.qml` lazily
instantiate presentation surfaces.

Context: Phase 4's theme selector required the previously missing stable
surface-opening convention. A single `qe` target would simplify the first CLI
command but would grow a shared integration boundary, couple unrelated optional
modules, and create parallel-development contention. Module-scoped targets keep
registration, tests, lifecycle, and degradation local.

Alternatives considered: one `qe` target with descriptive methods such as
`openThemeSelector`; presentation-owned handlers; a generic string-based
`open(surface)` router; direct domain mutation from IPC.

Consequences: the theme selector target is `qe-theme`, invoked for example with
`qs ipc call qe-theme toggle`. Future surfaces follow the same namespace and
method convention but register only when implemented. `SurfaceService` may
coordinate exclusivity later without absorbing IPC adapters. Existing external
desktop entries and Hyprland keybindings remain unchanged until their documented
cutover criteria pass. No QE IPC endpoint may unlock or carry authentication
responses.

Affected areas: shell assembly, transient surface lifecycle, IPC adapters,
Hyprland bindings at later cutovers, module tests, and future launcher/help and
control-center surfaces.

Revisit if: Quickshell adds a typed hierarchical IPC namespace or operational
evidence shows separate target registration harms reliable reload behavior.

## ADR-017: Keep external operation identity at the QE adapter boundary

Status: Accepted as part of the approved Phase 4 machine contract on 2026-08-25

Decision: use the switcher's schema-v1 document as durable external desktop
state without a QE operation ID. `ThemeService` assigns a local operation ID
before invoking machine mode, `CommandRunner` carries it through the bounded
process lifecycle, and stale process results are rejected by that local ID.

Context: the switcher remains independently usable, and its persisted document
describes external state that may be produced by QE, its human CLI, or another
machine caller. Persisting a QE-generated ID would imply QE ownership and would
not identify independent invocations meaningfully. QE still needs operation
identity to prevent stale process completion from overwriting current UI state.

Alternatives considered: require every switcher caller to provide and persist an
operation ID; let QE infer result identity only from requested theme; omit
operation association in QE.

Consequences: the machine syntax remains
`run.sh --machine --theme <id> [--skip-gtk]`; its state/result schema contains
theme, status, timestamp, persistence, error, and per-target outcomes but no
caller identity. QE serializes theme requests through an active external phase
and associates only direct process results with its local operation ID. File
watch updates are external state observations and never complete a QE operation
or mutate the active QE theme.

Affected areas: external switcher schema v1, `ExternalThemeAdapter`,
`ThemeService`, selector status, command fixtures, and external state watching.

Revisit if: the switcher adds concurrent remote callers that require shared
cross-process request correlation rather than independent durable state.

## ADR-018: Stage QE wallpaper themes before promotion

Status: Accepted as part of the Phase 4 wallpaper implementation on 2026-08-25

Decision: Matugen output mapped to the QE `Wallpaper` schema is written to a
per-operation staging path under the QE data directory. A dedicated promotion
adapter atomically renames the staged artifact into the catalog-visible
`Wallpaper.json` path only after the staged write succeeds.

Context: direct writes to the catalog-visible generated file made the current
foundation safe at the single-file level but did not expose a distinct
generation/promotion boundary. The Phase 4 contract requires generated output
to remain out of authored themes and to retain the complete last-known-good set
when generation or promotion fails.

Rationale: keeping staging and the target on the same filesystem gives the QE
artifact a replace operation with clear failure semantics. The adapter remains
replaceable when approved external Matugen targets add more artifacts.

Alternatives considered: write directly with `FileView.atomicWrites`; invoke
Matugen templates from the shell; implement multi-artifact promotion in QML.

Consequences: an interrupted generation can leave an unpromoted staging
directory, which is harmless derived data and can be cleaned in a later startup
maintenance step. External artifact promotion and compositor application remain
separate contracts; this ADR does not authorize edits to the legacy picker.

Affected areas: `WallpaperService`, `MatugenAdapter`,
`WallpaperPromotionAdapter`, generated QE theme state, and Phase 4 fixtures.

Revisit if: external generated artifacts require cross-filesystem promotion or
an atomic directory-set replacement rather than per-artifact replacement.

## ADR-019: QE-generated external wallpaper theme slots

Context: the architecture promised Matugen output that includes "configured
external application artifacts", but the external target contracts were not
approved. The accepted model is that QE owns generation and the external
theme-switcher owns external application, so QE must produce theme files the
switcher's existing apply scripts consume without writing any live config.

Decision: while the active QE theme is `wallpaper`, QE maps the captured
Matugen palette into a `wallpaper` theme slot per supported app and promotes
each file atomically into the app-specific slot (kitty, bat, btop, eza, dunst,
fzf, hyprland, hyprlock, imv, mpv, rofi, starship, tmux, opencode, and Yazi)
plus an nvim palette JSON under XDG cache for the local `colors/wallpaper.vim`
colorscheme. `WallpaperExternalThemeAdapter` materializes a validated spec via
`scripts/promote-external-theme.sh`, skips targets whose executables are
absent, and reports per-target results. QE never writes active application
configuration; after promotion it delegates `--machine --theme wallpaper
--skip-gtk` to the switcher, which performs the documented copy-to-active.
imv and mpv consume generated background slots, while Yazi consumes its
generated semantic palette and syntax file.
GTK is excluded because Matugen has no GTK generator.

Rationale: this preserves standalone switcher function, avoids two owners of
the same live config, and keeps "wallpaper" a normal theme ID from the
switcher's perspective. Applying a wallpaper always regenerates the QE
Wallpaper theme and slot files so the generated theme stays selectable;
external application is delegated only while the wallpaper theme is active,
which prevents a wallpaper change from overwriting fixed external themes.

Alternatives considered: QE writing external live configs directly (creates
file contention with the switcher); Matugen native template output (rejected
in favor of QE-owned generation); installing `matugen.nvim` for nvim
(extra plugin dependency and palette-format coupling; the local colorscheme
avoids both while remaining swappable for the plugin later).

Consequences: external slot files are derived data written into app config
trees by approved contract; failed or skipped targets are reported without
rolling back already-promoted files. Promotion is content-idempotent and
follows restore-managed slot symlinks, so generation never rewrites a tracked
default. The QE repository keeps authored defaults under `defaults/wallpaper`.
The preflighted `qe-defaults restore` command restores the stable XDG QE theme,
wallpaper/lockscreen images, Neovim palette, and external runtime files before
creating or repairing ignored live slot links; `capture` is the intentional
default-change operation. This makes
the generated QE `wallpaper` theme selectable before the first wallpaper
selection on a fresh installation. The self-contained nvim colorscheme means
neovim follows the wallpaper only while the wallpaper theme is active. The
generated catalog is refreshed after atomic replacement, and wallpaper
external application has one generation-completion dispatch point to avoid
concurrent switcher requests. Generated QE tokens use `#AARRGGBB` alpha to
match authored themes, and the generated `wallpaper` rofi colorscheme defines
the full variable set the main rofi theme references. opencode loads and caches
its theme colors at launch, so a regenerated wallpaper theme requires an
opencode restart even when the switcher live-re-selects the theme name in
tmux-hosted instances. imv, mpv, and Yazi similarly require new instances to
load regenerated configuration.

Affected areas: `ExternalWallpaperTheme.mjs`, `WallpaperExternalThemeAdapter`,
`promote-external-theme.sh`, `WallpaperService`, `ThemeService`,
`ExternalThemeAdapter`, nvim `colors/wallpaper.vim`, and Phase 4 fixtures.

Revisit if: an external app changes its theme slot layout, a target needs
cross-filesystem promotion, or the user selects `matugen.nvim` as the nvim
consumer.

## ADR-020: Apply-time focused Kitty bar compositing

Context: generated wallpaper themes used a fixed QE panel alpha and Matugen's
surface color, while Kitty separately applied its background opacity and
Hyprland applied window opacity. This made the generated bar visibly differ
from a focused Kitty window, especially for automatically generated palettes.

Decision: when generating the wallpaper theme, QE captures Kitty's effective
`background_opacity` and queries Hyprland's live
`decoration:active_opacity`. The generated `surface_panel` uses the Matugen
wallpaper background with the product of those values as its alpha. Kitty and
Hyprland remain the owners of their settings; QE does not introduce a shared
opacity setting or runtime watchers. Missing configuration files, missing
settings, unavailable IPC, malformed values, and out-of-range values use full
opacity (`1.0`). A later upstream change is reflected when the wallpaper theme
is next generated or applied.

Rationale: this matches the requested focused-window appearance without
polling or duplicating Kitty configuration. Applying the alpha to the bar is
necessary because Hyprland window opacity does not automatically apply to the
QE layer surface.

Alternatives considered: watching both configuration sources (unnecessary
runtime work and more lifecycle complexity); adding a QE-owned Kitty opacity
setting (creates competing ownership); using the Matugen surface token (does
not match Kitty's terminal background).

Consequences: an already-generated theme can remain stale after an upstream
opacity edit until the next wallpaper-theme application. Kitty include files
are resolved by the bounded helper, while Hyprland is queried from the live
compositor rather than assuming a config filename or syntax.

Affected areas: `MatugenAdapter`, `Matugen.mjs`, `Opacity.mjs`,
`qe-window-opacity.sh`, generated wallpaper themes, and validation fixtures.

Revisit if: Kitty or Hyprland expose a stable native event/API that makes
live synchronization valuable, or if the bar must match inactive windows too.

## ADR-022: Project-owned authored defaults bundle

Status: Accepted by user

Context: the default theme was a behavior-config field in `config/qe.json`,
while wallpaper images and generated wallpaper-theme artifacts were captured by
a dotfiles-owned `qe-wallpaper-default` helper. Changing or restoring the
desktop default therefore required two owners and two workflows.

Decision: QE owns one authored bundle under `defaults/`. The validated
`defaults/manifest.json` owns `defaultTheme`; `DefaultsService` exposes it to
`ThemeService`, while persisted active theme state remains separate. Wallpaper
images live under `defaults/wallpaper/images`, and generated QE/application
theme artifacts live under `defaults/wallpaper/generated-theme`. The
project-owned `scripts/qe-defaults capture|restore` command is the sole bundle
writer. Capture reads confirmed active state through typed IPC and promotes a
fully staged snapshot. Restore preflights all files, repairs runtime links, and
applies the manifest theme through running QE or the external switcher fallback.

Rationale: theme, wallpaper, and generated wallpaper-theme defaults form one
desktop-state snapshot rather than general shell behavior configuration. One
project owner makes capture reviewable, avoids cross-repository synchronization,
and keeps runtime XDG state distinct from authored defaults.

Alternatives considered: retain `defaultTheme` in `config/qe.json` (mixes
captured state with manually authored behavior settings); keep wallpaper
defaults in dotfiles (split ownership); automatically clear Quickshell state
while QE is stopped (couples the helper to hashed internal state and can destroy
an unrelated active selection).

Consequences: `config/qe.json` no longer contains `defaultTheme`; a malformed
manifest degrades to the safe Poimandres default. Capture requires a running QE
instance and refuses pending operations. Restore can materialize files before QE
starts, but only a running QE instance can confirm live QE theme and wallpaper
application. External application remains best effort and does not roll back
restored files.

Affected areas: `DefaultsService`, `ThemeService`, defaults schemas and files,
typed theme/wallpaper IPC, `scripts/qe-defaults`, dotfiles runtime-slot ignores,
and default-management documentation and fixtures.

Revisit if: QE gains a stable process-independent control endpoint or the
authored defaults need versioned migration beyond the manifest schema.

## ADR-021: Vim-style selector navigation convention

Status: Accepted by user

Decision: focused QE windows with selectable elements support lowercase `h`, `j`,
`k`, and `l` as aliases for left, down, up, and right arrow navigation. A
lowercase `q` is an alias for Escape when Escape dismisses the focused window.
Native arrow keys, Escape, and existing activation keys remain supported. A
surface with a text query field may use a documented modifier for vim-style
navigation; the Phase 7 launcher uses `Alt+h`, `Alt+j`, `Alt+k`, and `Alt+l`.

Context: the theme and wallpaper selectors use focused grid views and already
support keyboard navigation and Escape dismissal. The user requested a
consistent vim-style alternative for these selectors and future QE surfaces.

Rationale: the convention provides efficient keyboard navigation without
removing standard keyboard behavior or changing compositor-owned global
keybindings. Handling remains local to the focused selectable view, preserving
view-local interaction ownership.

Consequences: future selectable QE windows should expose the same aliases when
they provide arrow-key navigation or Escape dismissal. Uppercase or modified
vim keys are not aliases, so they remain available to controls that need them.

Affected areas: `modules/theme/ThemeSelector.qml`,
`modules/wallpaper/WallpaperSelector.qml`, and future selectable QE surfaces.

Revisit if: a future input method requires different modified vim keys, or a
shared keyboard-navigation component becomes justified by additional surfaces.

## ADR-028: QE-generated Yazi wallpaper flavor

Status: Accepted by user

Decision: generate Yazi's `wallpaper` flavor from the Matugen semantic palette as
one shell palette plus one TextMate syntax file. Promote both files into the
`wallpaper.yazi` slot, then let the external switcher generate `flavor.toml` from
Yazi's shared template and select the flavor through `theme.toml`.

Context: the external switcher's Yazi integration was redesigned to use a single
semantic palette source and a shared flavor template. Yazi also requires a
`tmtheme.xml` syntax artifact, so a palette-only integration would not satisfy
the existing apply contract.

Rationale: QE and the switcher share one wallpaper-derived color source while
Yazi retains ownership of template expansion and active-flavor selection. The
switcher replaces only generated `flavor.toml`, preserving restore-managed slot
links and unrelated Yazi configuration.

Consequences: QE reports two Yazi promotion results, and missing Yazi skips both
artifacts. Capture migrates a directly-generated Yazi slot into QE runtime state
and repairs its link when the slot has not yet been restored. Existing Yazi
instances do not reload a changed flavor and require a restart. The generated
Yazi syntax colors are intentionally derived from the same palette rather than
copied from an authored flavor.

Affected areas: `ExternalWallpaperTheme.mjs`, `apply_yazi_theme.sh`,
`scripts/qe-defaults`, generated wallpaper artifacts, and Yazi integration
fixtures.

Revisit if: Yazi gains reliable live theme reload or changes its flavor slot
contract.

## ADR-023: QE-generated imv and mpv wallpaper slots

Status: Accepted by user

Decision: generate dedicated `wallpaper` background slots for imv and mpv from
the current Matugen palette. The external switcher's imv and mpv scripts consume
those slots when applying `wallpaper`; authored themes continue using their
existing static mappings.

Context: adding a fixed `wallpaper` value to each switcher script would make the
theme stale after the next wallpaper change. imv and mpv use different config
syntax, but both expose a single background color relevant to this integration.

Rationale: generated slots preserve the established QE generation and external
switcher ownership boundary while allowing every wallpaper change to update the
actual color. The scripts validate the generated slot before editing the active
config.

Consequences: QE adds imv and mpv to wallpaper promotion and defaults capture/
restore. Missing applications are skipped by the existing executable checks;
missing or malformed wallpaper slots are reported as target failures. Existing
imv and mpv processes are not restarted and require a new process to load the
updated configuration.

Affected areas: `ExternalWallpaperTheme.mjs`, `apply_imv_theme.sh`,
`apply_mpv_theme.sh`, `scripts/qe-defaults`, generated wallpaper artifacts, and
external-theme fixtures.

Revisit if: either application changes its configuration syntax or gains a
reliable runtime background update path.

## ADR-024: Isolated QE notification ownership prototype

Status: Accepted by user on 2026-08-29

Decision: implement notification ownership through the native Quickshell
`NotificationServer`, with a separate structured DBus owner watcher for readiness
and diagnostics. DND suppresses Low and Normal popups but retains their
current-process history; Critical notifications remain visible. The Phase 5
acceptance test may stop Dunst in the current graphical session only within a
trapped stop/test/restart procedure. Production Dunst disablement, keybinding
migration, legacy producer changes, and hardware OSDs remain deferred to Phase 6.

Context: the notification DBus name is exclusive, while Quickshell 0.3.1 exposes
notification capabilities and objects but no QML property reporting successful
service acquisition. Dunst currently owns the name through a static DBus-activated
user service, and existing hardware producers still target Dunst.

Rationale: native notification delivery preserves Quickshell object lifetime and
event handling. A structured owner boundary prevents QE from claiming readiness
when Dunst or another service owns the name. The trapped test preserves the daily
fallback without pretending that two notification servers can coexist.

Alternatives considered: one-shot owner probes, early production Dunst disablement,
and keeping notification work entirely behind Dunst. One-shot probes do not report
owner loss promptly; early disablement violates staged migration; deferral provides
no validation of the notification contract.

Consequences: Phase 5 requires an independently tested owner-watcher contract,
bounded untrusted-content rendering, and explicit owner checks before and after the
exclusive test. Notification history is intentionally lost when QE exits, and
existing Dunst-based keybindings and producers remain the rollback path.

Affected areas: `NotificationService`, `NotificationsIntegration`, notification
modules, owner-watcher helper, notification configuration, diagnostics, and Phase 5
validation scripts.

Revisit if: Quickshell exposes reliable notification ownership state, or a separate
DBus test session becomes necessary to protect the primary session.

## ADR-025: QE-owned OSD and reversible action cutover

Status: Accepted for Phase 6 implementation

Decision: hardware feedback is owned by an independent QE OSD service rather than
being sent through desktop notifications. Hardware keybindings call typed QE
IPC actions. Dunst is blocked with a reversible user-service mask only after
the switcher's Dunst target is retired, and rollback restores the original
bindings, target list, service activation, and legacy producers.

Context: Dunst and QE cannot own `org.freedesktop.Notifications` concurrently.
The existing hardware scripts also combine subsystem mutation with Dunst
feedback, while native PipeWire and MPRIS APIs are available for the required
operations.

Rationale: separating OSD feedback from notification delivery prevents a
notification-owner failure from breaking hardware controls, preserves truthful
pending/confirmed state, and makes the ownership transition independently
reversible. The user selected persistent masking in the symlinked dotfiles
systemd directory and approved preservation of the legacy volume semantics.
The presentation policy uses one active slot so newly triggered feedback is
visible immediately and superseded state is not replayed after its relevance
has passed.

Consequences: Phase 6 adds OSD/action fixtures, native microphone and media
coverage, and a keyboard LED adapter. The external theme switcher continues to
support Dunst as a source target but skips it through the validated retirement
list after cutover.

Revisit if: QE gains a native action transport that is more stable than the
current namespaced IPC contract, or keyboard LED discovery cannot be made
portable without a user-authored device override.

## ADR-026: Notification center as a layer-shell sidebar

Status: Accepted by user on 2026-08-30

Decision: implement a reusable `components/Sidebar.qml` around a Quickshell
`PanelWindow` on the Wayland `WlrLayer.Overlay` layer instead of a normal
Hyprland-managed window. The panel uses ignored exclusive zones,
top/bottom/right anchors, and
20px outer screen margins. Its bottom margin additionally includes the enabled
bottom bar height when the bar is docked at the bottom. Its width is the 384px
notification-card maximum plus the existing 20px content margins. Notification
card layout and styling remain unchanged.

Context: the existing `FloatingWindow` is a normal compositor-managed window,
so its visibility and workspace placement are subject to Hyprland window
behavior. The notification center must overlay normal windows and remain
available while switching workspaces.

Rationale: layer-shell surfaces are compositor-owned panels and are presented
independently of normal workspace window placement. The overlay layer places
the sidebar above normal windows, while ignored exclusive zones prevent it from
altering application layout. Matching the card maximum and existing margins
avoids unnecessary width and preserves the established card presentation.

Consequences: the notification center is Wayland-specific in its overlay
behavior and is no longer represented as a normal Hyprland client. Pointer
interaction remains available without taking keyboard focus. Multi-monitor
placement continues to follow the existing notification surface screen
selection.

Affected areas: `components/Sidebar.qml`, `NotificationCenter.qml`,
notification-center lifecycle tests, and overlay/sidebar validation.

Revisit if: notification-center placement must become configurable per monitor,
or a non-Wayland backend requires an alternate surface implementation.

## ADR-027: Dedicated sidebar surface token

Status: Accepted by user on 2026-08-30

Decision: add `surface_sidebar` as a required semantic theme token and make the
reusable `components/Sidebar.qml` consume it by default. Poimandres uses its
`palette.black` color with alpha `f5` (`#f5171922`). Gruvbox adds
`palette.sidebar` as `#1d2021` and uses the corresponding alpha color
`#f51d2021`. The generated wallpaper theme derives its sidebar source color by
reducing the Matugen background's HSL lightness by 9/255 while preserving hue
and saturation, then applies the existing captured opacity.

Context: `surface_panel` is shared by bars, selectors, and panels, while the
sidebar needs a distinct darker surface. Matugen's optional `surface_container*`
colors do not guarantee the required relationship across variants.

Rationale: a schema-wide semantic role keeps normal components independent of
raw palette names. The measured HSL delta matches the requested Gruvbox
separation without imposing Gruvbox's cool tint on generated wallpaper themes.

Consequences: the theme-v1 contract expands from 32 to 33 roles. Runtime
validation, JSON Schema, emergency fallback, authored themes, fixtures, the
generated wallpaper artifact, and theme tests must be updated together.

Affected areas: `components/Sidebar.qml`, `utils/Matugen.mjs`, theme schema and
validation, authored and generated themes, and theme/QML validation.

Revisit if: generated wallpaper palettes need a user-configurable sidebar
darkening amount or a distinct sidebar foreground role.

## ADR-029: Persist successful launcher usage counts

Status: Accepted by user on 2026-08-31

Decision: the Phase 7 launcher records successful main-command launches as
QE-owned usage records, keyed by stable desktop-entry ID and persisted in
versioned `launcher-usage.json` state separate from authored configuration. The
document has an `entries` object mapping IDs to `launchCount`. It retains at
most 512 records, prunes IDs no longer present, and ranks empty-query results
by launch count before normalized name and stable ID. For non-empty queries,
search relevance precedes usage count. Terminal entries are excluded from v1.

Context: Quickshell provides the desktop-entry model and structured commands but
does not provide usage-based sorting. A session-only count would not satisfy
the meaning of frequently used, while adding usage tracking to user config would
mix generated behavior with authored settings.

Consequences: LauncherService owns loading, validation, in-memory updates, and
atomic persistence of usage state. A persistence failure does not fail a
successful launch; it leaves the current-process count updated and reports a
bounded diagnostic. Malformed or incompatible state starts empty without
blocking the launcher.

Affected areas: LauncherService, launcher ranking utilities, XDG state schema,
launcher tests, and the Phase 7 acceptance/rollback validation.

## ADR-030: Launch terminal applications through the configured terminal

Status: Accepted by user on 2026-09-01

Decision: the Phase 7 launcher includes eligible desktop entries marked
`Terminal=true`. When launching one, `LauncherService` prepends the value of
`$TERMINAL` (falling back to `kitty`) and the `--` argument to the structured
desktop-entry command. Arguments remain an array and are never passed through a
shell.

Context: useful TUI applications such as `jellyfin-tui` and `btop` are commonly
registered as terminal desktop entries. Excluding them makes the launcher omit
valid applications, while guessing or parsing a terminal command from a shell
string would violate the structured-launch boundary.

Consequences: terminal entries require a usable terminal emulator in `$TERMINAL`
or the fallback `kitty`. Usage counts represent successful terminal launches in
the same way as graphical launches. The launcher does not add a new terminal
configuration field in this phase.

Affected areas: launcher eligibility and launch command construction, launcher
tests, Phase 7 documentation, and the terminal application acceptance matrix.

Revisit if: QE adds an authored terminal-emulator configuration or needs
terminal-specific arguments beyond the standard `--` separator.

## ADR-031: Launcher uses a centered overlay panel

Status: Accepted by user on 2026-09-01

Decision: the launcher uses a transparent, non-exclusive `PanelWindow` on the
overlay layer for the focused monitor. Its visible surface is centered, is 35%
of the monitor width, and sizes to one through six result rows. Empty results
use the one-row minimum. The top edge is positioned from the six-row centered
baseline, so shorter states shrink from the bottom. It does not reserve screen
space for normal windows.

Context: the launcher must consistently overlay normal windows and remain
usable across monitor sizes without depending on compositor-managed floating
window placement. Showing six rows without a fixed-height empty area keeps the
surface compact for short result sets.

Consequences: the panel host spans the selected monitor, while the styled
launcher surface remains centered within it. The panel takes exclusive keyboard
focus only while visible and uses the existing launcher lifecycle to destroy or
hide the surface.

Affected areas: launcher presentation, focused-monitor placement, and Phase 7
manual overlay validation.
