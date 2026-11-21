# ADR-015: Adopt Matugen-style paired semantic roles before release

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
