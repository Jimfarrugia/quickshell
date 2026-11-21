# ADR-041: Use the existing login PAM service for the QE lock

Status: Accepted with Phase 12 start on 2026-09-07

Decision: the initial QE lock configures Quickshell `PamContext` with the
existing `/etc/pam.d/login` service. QE does not create or modify a PAM service
file during Phase 12.

Context: Quickshell 0.3.1 defaults to `login`. The installed
`/etc/pam.d/hyprlock` file contains only an authentication include of `login`, so
the current lock already authenticates through that stack. Selecting `hyprlock`
would unnecessarily retain a legacy package-owned service name after cutover; a
dedicated service would require a separately approved system change.

Consequences: initial QE authentication uses an existing system-owned stack and
does not depend on Hyprlock's PAM file. Its suitability must still pass
disposable and controlled live authentication tests. Any future dedicated PAM
service requires security review, explicit approval, and the system-change
procedure.
