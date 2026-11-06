# Shared helpers for the Android emulator checks (sourced, not run).
# Needs the Android SDK's adb on PATH, one emulator (or device) online, Node and curl.
# The emulator reaches the host's stub ingest at 10.0.2.2.

adb_ready() {
  serial="${ANDROID_SERIAL:-$(adb devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')}"
  [ -n "$serial" ] || { echo "FAIL no emulator online (start one first: emulator -avd <name>)"; exit 1; }
  export ANDROID_SERIAL="$serial"
  adb wait-for-device
  until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do sleep 2; done
  echo "emulator $serial (Android $(adb shell getprop ro.build.version.release | tr -d '\r'))"
}

# Installs the APK fresh (so the launch is a first launch) and starts its launcher activity.
apk_fresh_launch() { # apk package
  adb uninstall "$2" >/dev/null 2>&1 || true
  adb logcat -c || true
  run_logged adb-install adb install -r "$1"
  activity="$(adb shell cmd package resolve-activity --brief -c android.intent.category.LAUNCHER "$2" | tr -d '\r' | tail -1)"
  run_logged app-launch adb shell am start -W -n "$activity"
}

# Asserts what the stub received from package $1 with user id $2; prints ok/FAIL lines.
stub_assert_android() { # package userId [expected sdk.version]
  curl -sf "http://127.0.0.1:$stub_port/__requests" > "$work/requests.json"
  node - "$work/requests.json" "$1" "$2" "${3:-}" <<'JS'
const [file, appId, userId, expectedVersion] = process.argv.slice(2);
const all = JSON.parse(require('fs').readFileSync(file, 'utf8'));
const installs = all.filter((r) => r.route === 'installs' && r.body && r.body.appId === appId);
const install = installs[0];
const ref = install && install.body.installReference;
const identifies = all.filter((r) => r.route === 'identify' && r.body && r.body.installReference === ref);
let failed = 0;
const check = (ok, name) => { console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}`); if (!ok) failed++; };
check(installs.length === 1, `one install from ${appId} (got ${installs.length})`);
check(install && install.status === 202, 'the stub accepted it (contract valid)');
check(install && install.body.platform === 'android', 'platform android');
check(install && install.body.sdk && install.body.sdk.name === 'fload-attribution-android', 'sent by the Kotlin SDK');
check(install && install.body.playReferrer && !install.body.appleAds, 'carries playReferrer, not appleAds');
check(install && install.keyPrefix === 'fload_pk_', 'write key header');
const linked = (install && install.body.appUserId === userId) || identifies.some((r) => r.status === 202 && r.body.appUserId === userId);
check(linked, `user id ${userId} reached the stub`);
if (expectedVersion) check(install && install.body.sdk && install.body.sdk.version === expectedVersion, `sdk.version is the pinned ${expectedVersion}`);
console.log(`playReferrer: ${JSON.stringify(install && install.body.playReferrer)}  sdk: ${JSON.stringify(install && install.body.sdk)}`);
require('fs').writeFileSync(file + '.ref', ref || '');
process.exit(failed ? 1 : 0);
JS
  # The example logs what getInstallReference() returned through the bridge; it must
  # be the reference the SDK sent.
  sent="$(cat "$work/requests.json.ref")"
  if adb logcat -d | grep -q "Fload example: install reference $sent"; then
    echo "ok   getInstallReference() returned the sent reference ($sent)"
  else
    echo "FAIL getInstallReference() did not log $sent; console lines:"
    adb logcat -d | grep "Fload example" | tail -5
    exit 1
  fi
}
