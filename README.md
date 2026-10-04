# Character Test v0.0.8
Godot 4.3 character playtest with a rainy night crossroads, solid environment
boundaries, grounded animation, polished directional movement and two energy attacks.

Read **PATCH-NOTES.md** for installation, changes, limits and validation.

## Browser testing (recommended)
Apply this patch, enable repository Settings > Pages > Source: GitHub Actions,
then run **Build and deploy browser test** from Actions. Later pushes to main
publish automatically. The deployment summary contains the live test URL.

Expected URL after deployment: https://tomangamez-star.github.io/Godot-game-/

Rotate your phone to landscape. Tap Play; use the left joystick and the two attack
buttons on the right. Desktop: WASD / arrow keys, Space and E. WebGL 2 is required.
Fullscreen/orientation locking depends on browser support.

## APK (optional milestone test)
Run **Build Character Test APK** manually. Download the v0.0.8 artifact.
This is still a debug-signed test APK, not a store release. The default icon can
be replaced later. Existing app package ID and CPU architectures are preserved.

## Local
Import project.godot in Godot 4.3, then F6/F5.
For the automated smoke test:
```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/smoke.gd
```
No sprites are redistributed separately; original license remains in assets.
