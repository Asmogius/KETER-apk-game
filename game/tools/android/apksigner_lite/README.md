# apksigner, for when the Android SDK can't be had (0.26)

Godot's Android export (no Gradle) needs only one tool from the Android SDK:
`build-tools/<version>/apksigner`, to sign the app. Where Google's SDK server
can't be reached, `Sign.java` here does the part of it Godot calls (`--version`,
`sign`, `verify`), over Google's own `apksig` library from Maven Central
(`com.android.tools.build:apksig:2.3.0`). It signs with APK Signature Scheme
v2 only, which every phone the game runs on (Android 7, API 24, and later)
checks; that library's v1 signer leans on parts of the JDK that are gone.

    mkdir -p sdk/build-tools/34.0.0 sdk/platform-tools sdk/signer
    curl -sLo sdk/signer/apksig.jar https://repo1.maven.org/maven2/com/android/tools/build/apksig/2.3.0/apksig-2.3.0.jar
    javac -cp sdk/signer/apksig.jar -d sdk/signer Sign.java
    printf '#!/bin/sh\nexec java --add-exports java.base/sun.security.x509=ALL-UNNAMED --add-exports java.base/sun.security.pkcs=ALL-UNNAMED --add-exports java.base/sun.security.util=ALL-UNNAMED -cp "%s/sdk/signer:%s/sdk/signer/apksig.jar" Sign "$@"\n' "$PWD" "$PWD" > sdk/build-tools/34.0.0/apksigner
    printf '#!/bin/sh\necho "Android Debug Bridge version 1.0.41"\n' > sdk/platform-tools/adb
    chmod +x sdk/build-tools/34.0.0/apksigner sdk/platform-tools/adb

Then point Godot's editor setting `export/android/android_sdk_path` at `sdk`
(or set `ANDROID_SDK`) and run `python3 make_game.py android` as usual. The
app is signed with `../keter_release.keystore.b64`, as every build is, so it
installs over the last one and keeps its saves.
