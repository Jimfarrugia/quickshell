# ADR-022: Project-owned authored defaults bundle

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


Identifier note: the source plan contained two different accepted records
numbered `ADR-022`. The user resolved the collision by keeping `ADR-022` for
this decision and assigning `ADR-028` to the later Yazi wallpaper flavor
decision. Never renumber, merge, or delete an accepted ADR to tidy the sequence.
