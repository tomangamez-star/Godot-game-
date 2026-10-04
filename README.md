# Character Test v0.0.1

White-background Godot 4.3 character-controller test. Includes the original HD male character, left joystick, right attack button, four directional sprite animations, 12 FPS running, 16.67 FPS energy-slash attack, and movement lock during attacks. Diagonal movement uses the closest of four facing directions. No enemies or extra gameplay systems.

## Android APK

Extract this ZIP, then upload the CONTENTS of the extracted folder to the root of a new GitHub repository. Include `.github/workflows/build-apk.yml`. Open Actions, select Build Character Test APK, and Run workflow. Download the Character-Test-v0.0.1-APK artifact and extract the APK. This is a debug-signed test build, not a store release.

This phone-safe edition removes ZIP metadata and explicit folder records that some Android file managers fail to extract. The game project itself is unchanged.

## Local test

Import project.godot in Godot 4.3 and press F6/F5. Move with WASD/arrow keys or drag the left joystick; attack with Space or the right button. On mobile use two fingers for joystick and attack. Landscape orientation is configured.

## Validation status

Project structure and sprite dimensions checked during packaging. No Godot/Android SDK was available in the authoring workspace, so engine execution and APK compilation have not been verified there. The included workflow performs the actual import/export and reports any compiler errors. Character sheets are a first art pass: some attack trails touch neighbouring cells and foot alignment may need further art refinement. This test is intended to reveal those issues.
