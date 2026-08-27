# QE Defaults

`manifest.json` and `wallpaper/` are the authored default desktop snapshot.
Runtime wallpaper images and generated themes remain under their XDG data,
state, and cache paths; normal theme and wallpaper selection does not modify
this directory.

Use the project-owned helper to intentionally capture or restore the complete
default set:

```sh
qe-defaults capture
qe-defaults restore
```
