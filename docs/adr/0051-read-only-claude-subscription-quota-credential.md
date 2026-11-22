# ADR-051: Read-only Claude subscription quota credential

Status: Accepted by user on 2026-11-22

Decision: QE reads the Claude subscription quota through the same bounded
helper and read-only rules as ADR-036, using Claude Code's own OAuth credential
at `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.credentials.json`. The helper opens it
with the existing owner-only, no-symlink, size-bounded file reader and uses
only `claudeAiOauth.accessToken` and `expiresAt`. QE never writes, refreshes,
removes, or migrates that file; Claude Code remains the sole OAuth refresh
owner. The normalized QE provider identifier is `claude`.

The helper exposes only the `five_hour` and `seven_day` windows from
`https://api.anthropic.com/api/oauth/usage`, as the existing `fiveHour` and
`weekly` windows. A window with zero utilization and no reset time is a window
that has not started yet; it is reported as available with no reset time rather
than as unavailable. Any other missing reset time, or utilization outside 0-100,
is rejected under ADR-036's no-guessing rule.

Context: OpenCode holds no Anthropic credential for this user, so ADR-036's
store cannot supply it. Claude Code's credential file is the only local source,
and the usage endpoint is an undocumented OAuth beta endpoint rather than a
stable public API contract.

Consequences: an expired Claude access token stays unavailable or stale until
Claude Code next refreshes it. Claude credential failures are local to the
`claude` provider and do not depend on, or affect, the OpenCode store. Model-
specific weekly windows and extra-usage spend are not shown. Removing the
provider removes QE's dependency on Claude Code's credential file.

Alternatives rejected: refreshing the OAuth token in QE (it would rotate a
credential Claude Code owns), and parsing Claude Code's `/usage` output (no
machine-readable contract and it would start a CLI process per poll).
