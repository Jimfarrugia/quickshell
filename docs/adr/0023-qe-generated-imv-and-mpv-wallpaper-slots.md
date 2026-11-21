# ADR-023: QE-generated imv and mpv wallpaper slots

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
