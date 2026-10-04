# Character Test v0.0.7 — Night crossroads polish

Modified/new files only. Apply to repository root, preserving directories.
Base commit: 7b5926649111d9a37fc5ed32277c8256ead5f3fe.
Keep your existing assets and main.tscn. Nothing was pushed remotely.

## Changes

- Replaced the flat vector map with a project-integrated rainy anime city
  crossroads, generated from the supplied visual reference as a background-only
  environment. No reference HUD, characters or enemies are baked into it.
- Reduced character scale from 0.67 to 0.55. Slash reach, centre and contact
  shadow were reduced with it.
- Every source frame is measured at load time and positioned from its opaque
  foot pixels. The gameplay position now represents the actual floor contact
  point rather than the sprite centre.
- Restored a visible 14-step idle loop at 5.5 FPS, aligned independently for all
  four directions so the feet stay planted.
- Added a wet-surface reflection and a tighter pulsing contact shadow.
- Replaced the rectangular screen clamp with a road-shaped walkable polygon.
  Extra collision blockers cover the wrecked SUV, parked car, road barrier and
  lower-left street furniture. Movement slides along solid edges.
- Added foreground image regions that occlude the character beside lower walls,
  while the controls remain in a separate top HUD layer.
- Added lightweight animated rain over the environment.
- Preserved the attack-button cooldown animation.

- Idle: stable first pose with subtle upper-body breathing; no cycling through
  inconsistent front/back proportions.
- Running: read-only head-anchor measurement offsets each frame to reduce
  lateral jitter. Cadence follows actual movement distance, including slow
  joystick movement. Direction hysteresis reduces flicker near diagonals.
- Attack: anticipation, faster swing and recovery timing; late-tap buffering.
  Runtime shader suppresses the original bright baked effects and fades cell
  edges; a separate continuous energy ribbon is not limited to a sprite cell.
  This is a rendering workaround, not a repaint of the original sprite sheets.
  Existing pose/proportion inconsistencies and some baked trail residue may
  remain. Do not expect missing source-art pixels to be reconstructed.
- Environment: lightweight vector crossroads with curbs, pavements, crossings,
  lane markings, grass, corner beds, contact shadow and visible outer boundary.
  Movement is bounded; decorative bushes are not solid obstacles.
- Fixed 16:9 gameplay canvas with letterboxing, keeping mobile control positions.
- Web launcher: Play, fullscreen request, landscape request where supported,
  direct game link, exit. Mobile browsers may require manual rotation.
- Single-threaded Godot 4.3 Web export for ordinary GitHub Pages hosting.
- Content-aware browser cache retains unchanged engine files across game
  updates. Changed PCK files are downloaded in full, not as binary deltas.
- APK workflow is manual only. Both existing Android architectures retained:
  this patch does not promise a smaller APK or change device compatibility.
- Default Godot icon remains until a custom icon is chosen.

## Enable the browser test

1. Upload the extracted files to the repository root, including .github/workflows.
2. In repository Settings > Pages > Build and deployment, choose
   **Source: GitHub Actions**. Do not choose Deploy from a branch.
3. Open Actions > Build and deploy browser test > Run workflow on main.
4. Wait for build and deploy to finish. Open the URL in the deployment summary.
   Expected address: https://tomangamez-star.github.io/Godot-game-/
5. Open it on the phone, rotate to landscape and tap Play browser test.
6. Later commits to main rebuild the web test automatically. Reload the launcher
   after a successful deployment. APK remains available via its manual workflow.

The link is not live merely because this patch was downloaded. GitHub must build
and deploy it. Pages is public; there are no secrets in this game patch.

## Data use

The local export measured about 5.2 MiB for game.pck and 34 MiB for the engine
WASM before HTTP compression. First launch is still a substantial download.
With browser storage available, unchanged engine bytes are reused. Ordinary
game-only changes should typically replace the roughly 5.2 MiB game pack,
not a 53 MB APK. Browser eviction/private mode can require a full download.

## Validation

Godot 4.3 import, script smoke tests and release Web export run locally.
Tests cover all four idle/attack directions, attack completion, joystick
movement/release, bounds and focus reset. A visual-capture script is provided
for machines with a graphical display.
Workflow YAML and generated cache-worker JavaScript syntax were also checked.
Graphical browser validation was blocked by the execution environment's socket
permissions; no screenshot or on-device visual verification is claimed.

On-phone animation feel, multi-touch and hosted GitHub Pages deployment still
need your test. No APK was built for this patch.

## References

- https://docs.godotengine.org/en/4.3/tutorials/export/exporting_for_web.html
- https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site
