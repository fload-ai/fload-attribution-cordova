#!/bin/sh
# Plain-JVM test of src/android/.../PluginArguments.java against the classes of
# the pinned fload-attribution-android AAR (from JitPack) and the Kotlin standard
# library. Needs a JDK (17+), curl and unzip; no Android SDK.
set -eu
cd "$(dirname "$0")/.."
version="$(node -p "require('./package.json').floadNative.android")"
cache="${FLOAD_ANDROID_TEST_CACHE:-$HOME/.cache/fload-cordova-test}"
mkdir -p "$cache"
aar="$cache/fload-attribution-android-$version.aar"
[ -f "$aar" ] || curl -sfL -o "$aar" "https://jitpack.io/com/github/fload-ai/fload-attribution-android/$version/fload-attribution-android-$version.aar"
stdlib="$cache/kotlin-stdlib-2.1.0.jar"
[ -f "$stdlib" ] || curl -sfL -o "$stdlib" "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-stdlib/2.1.0/kotlin-stdlib-2.1.0.jar"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
unzip -q -o "$aar" classes.jar -d "$out"
cp="$out/classes.jar:$stdlib"
javac -Xlint:all -Werror -d "$out/classes" -cp "$cp" \
  src/android/com/fload/attribution/cordova/PluginArguments.java test/android/PluginArgumentsTest.java
java -cp "$out/classes:$cp" com.fload.attribution.cordova.PluginArgumentsTest
