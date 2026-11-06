#!/bin/sh
# The iOS half of the plugin on a simulator, against the local stub ingest: the
# example app on cordova-ios 8 (the plugin as a Swift package), built,
# installed fresh, launched, and what the stub received checked: one accepted
# install from the Swift SDK, user id linked. Needs Xcode with an iOS simulator,
# Node and npm. Shuts down the simulator if it booted it.
# Usage: sh scripts/ios-simulator-check.sh   (FLOAD_SIM_UDID=… to pick one)
set -eu
cd "$(dirname "$0")/.."
root="$PWD"
work="$(mktemp -d)"
stub_script="$root/scripts/stub-ingest.mjs"
. "$root/scripts/sim-common.sh"
trap 'finish; rm -rf "$work"' EXIT

sim_boot
stub_start 3999

echo "== example app"
# The plugin as npm would ship it (adding this folder itself would copy example/ into itself).
run_logged npm-pack npm pack --pack-destination "$work"
mkdir -p "$work/plugin" && tar xzf "$work"/fload-ai-attribution-cordova-*.tgz -C "$work/plugin"
cd example
rm -rf platforms plugins
run_logged example-npm-install npm install --no-audit --no-fund
run_logged cordova-platform-add-ios npx cordova platform add ios --nosave
run_logged cordova-plugin-add npx cordova plugin add "$work/plugin/package" --nosave
run_logged cordova-build-ios npx cordova build ios --emulator --debug
app="$(find platforms/ios/build "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 6 -path '*iphonesimulator*' -name '*.app' -type d -newer "$work" 2>/dev/null | head -1)"
[ -n "$app" ] || { echo "FAIL no .app built"; tail -60 "$work/cordova-build-ios.log"; exit 1; }
echo "app $app"
bundle="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Info.plist")"
xcrun simctl uninstall "$udid" "$bundle" 2>/dev/null || true
xcrun simctl install "$udid" "$app"
xcrun simctl launch "$udid" "$bundle"
if ! stub_wait_install "$bundle" 60; then echo "FAIL no install reached the stub in 60 s"; cat "$work/stub.log"; exit 1; fi
sleep 5
stub_assert "$bundle" "example-user-1" "$(node -p "require('$root/package.json').floadNative.ios")"
xcrun simctl terminate "$udid" "$bundle" || true
xcrun simctl uninstall "$udid" "$bundle" || true
echo "stub log:"; cat "$work/stub.log"
