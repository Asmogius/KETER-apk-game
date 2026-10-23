# The game as an Android app (0.19)

`python3 make_game.py android` (from the Companion's folder, beside `game/`)
builds the game as an Android app, `v<version>_KETER.apk`, that installs and
runs on a phone with no Godot. It needs:

- **Godot 4.7.2** (the `GODOT` environment variable, or the path in
  `make_game.py`) with its **export templates** installed (Godot's
  `export_templates/4.7.2.stable/`, holding `android_release.apk`).
- **A JDK** (17 or later) and **an Android SDK** with `build-tools/<version>/apksigner`
  and `platform-tools/adb` (the `ANDROID_SDK` environment variable, or the
  path in Godot's editor settings). No Gradle: Godot fills its own template.
- **The built Companion** (`pwa/`) and **Playwright**: the app carries an
  Export for Godot of the Companion as it ships (its test floors, the master
  cards, the World Map), made from it, as `exports/KETER_export_0000_built_in.zip`.

It is signed with the app's own key, `keter_release.keystore.b64` here
(base64; alias `keter`, password `keterketer`). Every build is signed with the
same key, so a new version installs over the old one and keeps what the game
has saved. A build signed with any other key can't be installed over it
without uninstalling first, which loses the saves.

What the app does differently from the project in the Godot editor:

- It plays the export built into it until it may read your **Downloads**: it
  asks for **All files access** at start (Android shows its settings page for
  KETER), and then uses the newest `KETER_export_….zip` in Downloads, where the
  Companion's Export for Godot lands. Look again (Home, or Options) finds a
  newer one.
- Everything else is as in the editor: it is held sideways, and its saves are
  the app's own (`user://`).
