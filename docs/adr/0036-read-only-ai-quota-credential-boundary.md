# ADR-036: Read-only AI quota credential boundary

Status: Accepted by user on 2026-09-04

Decision: QE reads OpenCode's provider credential store only through a bounded
helper running as the same unprivileged user. The helper is the only component
that handles credentials. QE never writes, refreshes, removes, or migrates
provider credentials; OpenCode remains the sole OAuth refresh owner. The
OpenCode Go credential is read from the `opencode-go` record in that store; its
normalized QE provider identifier remains `opencode`.

The helper returns only normalized weekly and five-hour quota windows. Tokens,
refresh tokens, account identifiers, authorization headers, raw responses, and
sensitive diagnostic detail never enter QML, command arguments, persistent state,
logs, or fixtures. Unknown or ambiguous provider windows are unavailable rather
than guessed, and retained values are explicitly marked stale.

Context: the requested OpenAI Codex/ChatGPT and OpenCode Go usage endpoints have
no suitable local event source and are not guaranteed stable public API
contracts. OpenAI OAuth refresh can rotate credentials owned by OpenCode.

Consequences: expired OpenAI access may remain stale until OpenCode refreshes
its own credential store. Provider and window failures remain local and cannot
block QE startup. Removing the feature removes QE's dependency on OpenCode's
external credential store.
