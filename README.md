# Fload Attribution for Cordova

Counts your app's installs in Fload and attributes them: to Apple Ads through
Apple's AdServices token on iOS, and to the Google Play Install Referrer on
Android. No IDFA, no advertising ID, no App Tracking Transparency prompt, no
events.

This plugin is a thin bridge over Fload's native SDKs,
[fload-attribution-ios](https://github.com/fload-ai/fload-attribution-ios) and
[fload-attribution-android](https://github.com/fload-ai/fload-attribution-android).
Everything they do (the offline queue, retries, what is sent) is described in
their READMEs.

Needs cordova-ios 8 or later (the plugin is a Swift package) and
cordova-android 13 or later. iOS 15 or later, Android 7 (API 24) or later.

## Install

```sh
cordova plugin add @fload-ai/attribution-cordova
```

**iOS.** cordova-ios 8 adds the plugin as a Swift package, and the plugin pulls
in `github.com/fload-ai/fload-attribution-ios`. Set the deployment target in
your `config.xml`:

```xml
<preference name="deployment-target" value="15.0" />
```

**Android.** The Kotlin SDK comes from [JitPack](https://jitpack.io). The plugin
adds the JitPack repository (for the `com.github.fload-ai` group only) and the
dependency to your app's Gradle build. To pin another 1.x version of the Android
SDK:

```sh
cordova plugin add @fload-ai/attribution-cordova --variable FLOAD_ATTRIBUTION_ANDROID_VERSION=1.0.1
```

## Use

```js
document.addEventListener('deviceready', async () => {
  // Once, early:
  await FloadAttribution.configure({ key: 'fload_pk_…' });

  // Optional: link your user id (e.g. RevenueCat's appUserID) to the install.
  await FloadAttribution.setUserId({ id: appUserId });
});
```

The key is your app's public write key from Fload. It can only report installs
for that one app, so it is safe to ship in the app.

| Call | What it does |
| --- | --- |
| `configure({ key, endpoint?, logLevel? })` | Starts the SDK. Returns at once; the native SDK works in the background. A second call is ignored. |
| `setUserId({ id })` | Links your user id to this install. Safe before `configure` and on every launch; each id is sent once. |
| `getInstallReference()` | `{ installReference }`: this install's random id, or `null` until the SDK has loaded. For support questions. |

Every call returns a Promise. `endpoint` is for testing against your own server;
`logLevel` is one of `none`, `error`, `warning` (the default), `info`, `debug`.
The SDKs never log the key, Apple's token, the referrer or a user id. TypeScript
types are in `types/index.d.ts`.

## Privacy

What the SDK collects and how to answer Apple's privacy questions and Google
Play's Data safety form: see the
[iOS](https://github.com/fload-ai/fload-attribution-ios#privacy) and
[Android](https://github.com/fload-ai/fload-attribution-android#google-play-data-safety)
READMEs. The iOS SDK ships its `PrivacyInfo.xcprivacy`.

## Example app

`example/` sends to a local stub of Fload's ingest, never to production:

```sh
npm run stub-ingest                 # terminal 1, in this folder: listens on :3999
cd example && npm install && npm run setup
npx cordova run android             # or: npx cordova run ios
curl -s localhost:3999/__requests   # what the stub received
```

The Android emulator reaches your machine at `10.0.2.2`, the iOS simulator at
`localhost`. The example allows plain `http` to those hosts only.

## Development

- `npm test`: the JS layer, with `cordova/exec` faked.
- `npm run test:ios-host`: the iOS argument checks on the host (`swiftc`, no
  Xcode needed), compiled with the pinned `fload-attribution-ios` sources.
- `npm run test:android`: the Android argument checks (JVM unit tests).

## License

MIT. See [LICENSE](LICENSE).
