# Security Architecture

Authoritative for credentials, authentication, lock safety, secret handling, and security-sensitive rendering/operation boundaries. Load this file for lock/PAM, network credentials, notification content security, or any new sensitive external integration.

## Security

- The lock uses `WlSessionLock` and checks `secure` before presenting itself as
  fully locked.
- PAM responses remain in lock-process memory only and are cleared immediately
  after response submission.
- The QE lock uses the existing `/etc/pam.d/login` stack. Hyprlock is retired;
  introducing a custom `/etc/pam.d` service still requires separate approval and
  a system change procedure.
- QE IPC is not an authentication boundary and never exposes unlock or raw PAM
  response methods.
- Network secrets are not persisted or logged by QE.
- AI provider credentials are read-only external data. They are never passed as
  command arguments, persisted, logged, returned by the helper, or exposed to
  QML; quota snapshots are non-persistent derived state.
- Notification markup, images, links, and actions are untrusted application
  input and require constrained rendering.
- Theme IDs, paths, desktop entries, notification actions, and helper output are
  validated before use.
- Helpers quote all paths, avoid shell interpolation, and reject path traversal.
- Diagnostics redact secrets and bound external output size.
- Power actions require explicit user activation and confirmation according to
  configuration; command availability does not imply authorization.
