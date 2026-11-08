// The plugin names itself on every request (sdk.wrapper) with its own version.
// Neither Swift nor Java can read package.json at build time, so each native
// side holds the version as a constant; these checks hold every copy equal to
// package.json, and the native pins to floadNative.
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.join(__dirname, '..');
const read = (file) => fs.readFileSync(path.join(root, file), 'utf8');
const pkg = JSON.parse(read('package.json'));
const pluginXml = read('plugin.xml');

test('plugin.xml carries the package version', () => {
  assert.equal(pluginXml.match(/<plugin\b[^>]*\sversion="([^"]+)"/)[1], pkg.version);
});

test('the iOS bridge names cordova at the package version', () => {
  const swift = read('src/ios/PluginArguments.swift');
  assert.deepEqual(swift.match(/FloadWrapper\(name: "([^"]+)", version: "([^"]+)"\)/)?.slice(1), ['cordova', pkg.version]);
});

test('the Android bridge names cordova at the package version', () => {
  const java = read('src/android/com/fload/attribution/cordova/PluginArguments.java');
  assert.equal(java.match(/WRAPPER_NAME = "([^"]+)"/)?.[1], 'cordova');
  assert.equal(java.match(/WRAPPER_VERSION = "([^"]+)"/)?.[1], pkg.version);
});

test('the native pins match floadNative', () => {
  assert.equal(read('Package.swift').match(/fload-attribution-ios\.git", from: "([^"]+)"/)[1], pkg.floadNative.ios);
  assert.equal(pluginXml.match(/name="FLOAD_ATTRIBUTION_ANDROID_VERSION" default="([^"]+)"/)[1], pkg.floadNative.android);
});
