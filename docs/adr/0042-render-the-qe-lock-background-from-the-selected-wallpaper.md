# ADR-042: Render the QE lock background from the selected wallpaper

Status: Accepted by user on 2026-09-08

Decision: retain Hyprpaper as the desktop wallpaper owner and add the
project-owned `qe-wallpaper` helper. The helper applies the original source
through Hyprpaper before normalizing an atomic `current_wallpaper.png`
last-known-good artifact. The existing legacy `wallpaper` script remains
untouched.

The isolated QE lock reads and validates the selected wallpaper before
acquiring `WlSessionLock`, preloads it with bounded dimensions, and renders it
per lock surface using `Image.PreserveAspectCrop` and `autoTransform`. A
transparent-to-black vertical gradient is composed in QML. Invalid or
undecodable wallpaper input uses the opaque lock fallback. Hyprlock rollback
and its generated wallpaper target are retired, but existing Hyprlock files
are not deleted by this change.

Context: ImageMagick generation of a second lockscreen raster delayed wallpaper
application and made the lock background a stale derived artifact. Quickshell
can reproduce the required image and gradient composition while retaining
Hyprpaper's established compositor wallpaper lifecycle. Replacing Hyprpaper
with a QE background surface is deferred until production supervision and
multi-output lifecycle validation are complete.

Consequences: the source wallpaper becomes visible immediately after accepted
Hyprpaper IPC, while the normalized LKG is generated afterward for Hyprpaper's
startup configuration. A successful helper result confirms IPC acceptance and
LKG promotion, not pixel presentation. Hyprlock is no longer a supported QE
rollback path.
