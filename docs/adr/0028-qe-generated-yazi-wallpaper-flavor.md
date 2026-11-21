# ADR-028: QE-generated Yazi wallpaper flavor

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


Identifier note: this decision was originally also numbered `ADR-022` in the
source plan. The user resolved the collision by assigning it `ADR-028`;
`ADR-022` remains the project-owned authored defaults bundle decision.
