#!/bin/sh
# The Android half of the plugin on an emulator, against the local stub ingest:
# the example app on cordova-android (the plugin from this checkout, the Kotlin
# SDK from JitPack), built, installed fresh, launched, and what the stub
# received checked: one accepted install from the Kotlin SDK with the Play
# referrer, user id linked.
# Needs a JDK (17+), the Android SDK (ANDROID_HOME, adb), Gradle on PATH (cordova-android
# uses it to make its wrapper), one emulator online, Node and npm.
# Usage: sh scripts/android-emulator-check.sh
set -eu
cd "$(dirname "$0")/.."
root="$PWD"
work="$(mktemp -d)"
stub_script="$root/scripts/stub-ingest.mjs"
. "$root/scripts/sim-common.sh"
. "$root/scripts/emulator-common.sh"
trap 'finish; rm -rf "$work"' EXIT

adb_ready
stub_start 3999

# The plugin as npm would ship it (adding this folder itself would copy example/ into itself).
run_logged npm-pack npm pack --pack-destination "$work"
mkdir -p "$work/plugin" && tar xzf "$work"/fload-ai-attribution-cordova-*.tgz -C "$work/plugin"
cd example
rm -rf platforms plugins
run_logged example-npm-install npm install --no-audit --no-fund
run_logged cordova-platform-add-android npx cordova platform add android --nosave
run_logged cordova-plugin-add npx cordova plugin add "$work/plugin/package" --nosave
run_logged cordova-build-android npx cordova build android --debug
apk="$(find platforms/android/app/build/outputs/apk/debug -name '*.apk' | head -1)"
[ -n "$apk" ] || { echo "FAIL no APK built"; exit 1; }
package="$(sed -n 's/.*<widget id="\([^"]*\)".*/\1/p' config.xml)"
apk_fresh_launch "$apk" "$package"
if ! stub_wait_install "$package" 90; then echo "FAIL no install reached the stub in 90 s"; cat "$work/stub.log"; adb logcat -d -s FloadAttribution:V chromium:V | tail -40; exit 1; fi
sleep 5
stub_assert_android "$package" "example-user-1"
adb shell am force-stop "$package" || true
adb uninstall "$package" >/dev/null 2>&1 || true
echo "stub log:"; cat "$work/stub.log"
