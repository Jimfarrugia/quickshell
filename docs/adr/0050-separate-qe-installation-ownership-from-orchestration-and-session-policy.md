# ADR-050: Separate QE installation ownership from orchestration and session policy

Status: Accepted as settled installation plan on 2026-09-12

Decision: QE owns its complete requirements, package-to-capability checks,
generic deployment assets, public commands, defaults bootstrap, authorized
Dunst mask, activation implementation, readiness, and receipt. Arch Setup owns
target-user/base preparation, the fixed privileged Pacman transaction, service
enablement, dotfiles deployment, and when QE is invoked. Dotfiles owns
user/session policy. QE verifies that caller-owned policy and does not rewrite
it. The authorized installer persists the Dunst mask before first live
activation and never restores Dunst after activation failure.

Context: duplicated package/deployment knowledge had coupled three repositories,
and folded Stow parents could redirect installer writes into dotfiles source.
Pre-login setup also cannot safely fabricate a graphical session, while a live
cutover must protect exclusive DBus ownership and correlate readiness to the
supervised process.

Consequences: production remains fixed at `$HOME/Projects/quickshell`; shared
deployment parents must be real directories; exact legacy forms may be adopted
but unknown user content is preserved and rejected. Static installation may
succeed as activation deferred. `qe-shell --service-start` is the sole live
activation/retry path and writes a process-independent receipt. This policy
supersedes ADR-008's acceptance-before-disablement ordering and ADR-025's
reversible dotfiles-owned Dunst-mask consequence while preserving both ADRs'
notification-owner safety rationale. Retirement of legacy `wallpaper` and
`select_wallpaper` entry points supersedes ADR-042's consequence that the old
`wallpaper` script remains untouched, without changing ADR-042's QE/Hyprpaper
ownership model.

Alternatives rejected: duplicate QE package lists in Arch Setup, keep generic
assets in dotfiles, enable the static unit against an unverified graphical
target, fabricate session variables pre-login, restore Dunst on failed
activation, or add broad migration/rollback/ownership databases.
