# Changelog

## 1.1.0 (2026-11-08)

- Native SDKs 1.1.0; installs name this wrapper (FLO-3957). Every request now
  carries `sdk.wrapper` `{ name: "cordova", version: "1.1.0" }`. An app that pins
  the Android SDK through `FLOAD_ATTRIBUTION_ANDROID_VERSION` needs 1.1.0 or later.
- Upgrading from 1.0.x: a pinned `FLOAD_ATTRIBUTION_ANDROID_VERSION=1.0.2` (as the
  1.0.0 README suggested) survives the plugin upgrade and keeps the old native
  SDK, so the Android build fails. Unpin it or set it to 1.1.0.

## 1.0.0 (2026-11-06)

- First release. Wraps fload-attribution-ios 1.0.2 and fload-attribution-android 1.0.2:
  configure, setUserId and the install reference.
