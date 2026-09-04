# Read-only AI quota credential boundary

Status: Accepted by user on 2026-09-04

QE may read OpenCode's provider credential store as the same unprivileged user
for displaying OpenAI Codex/ChatGPT and OpenCode Go quota. The helper is the
only component that receives credentials. QE never writes, refreshes, removes,
or migrates provider credentials, and OpenCode remains the sole OAuth refresh
owner.

The OpenCode Go credential is read from the `opencode-go` record in that store;
the provider's normalized QE identifier remains `opencode`.

The helper emits only a versioned, bounded, normalized quota document. Tokens,
refresh tokens, account identifiers, authorization headers, raw responses, and
credential errors containing sensitive detail never enter QML, command
arguments, persistent state, diagnostics, logs, or fixtures.

Quota data is best-effort live external state. QE relies on the provider usage
endpoints used by their clients even though those endpoints are not guaranteed
public API contracts. Unknown or ambiguous windows are unavailable rather than
guessed. Last-known values may be retained only with an explicit stale marker.

Consequences: an expired OpenAI access token can leave the displayed value stale
until OpenCode refreshes its own auth file. Removing the feature removes QE's
dependency on the external credential store.
