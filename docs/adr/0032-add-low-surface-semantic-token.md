# ADR-032: Add low surface semantic token

Status: Accepted by user on 2026-09-01

Decision: add required theme token `surface_low`, mapped to the same resolved
color as `surface_sidebar` in every authored, generated, and fallback theme.

Context: consumers need a semantic low-surface role while preserving the
existing sidebar color mapping and theme-specific palette ownership.

Consequences: the theme-v1 contract expands from 33 to 34 roles. Validators,
schemas, fixtures, fallbacks, and Matugen-generated themes must provide the
token together.
