#!/bin/sh
# Compiles the plugin's Cordova-free Swift (src/ios/PluginArguments.swift) with
# the pinned fload-attribution-ios sources for the host Mac and runs
# test/ios-host. Needs only a Swift toolchain and git; no Xcode or simulator.
set -eu
cd "$(dirname "$0")/.."
tag="$(node -p "require('./package.json').floadNative.ios")"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$tag" https://github.com/fload-ai/fload-attribution-ios.git "$out/sdk" 2>/dev/null
swiftc -O -module-name FloadAttributionPlugin \
  "$out"/sdk/Sources/FloadAttribution/*.swift \
  src/ios/PluginArguments.swift \
  test/ios-host/main.swift \
  -o "$out/host-tests"
"$out/host-tests"
