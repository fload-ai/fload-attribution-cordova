// What an app does at launch: configure once after deviceready, then name the user.
// The stub ingest runs on the host; the Android emulator reaches it at 10.0.2.2,
// the iOS simulator at localhost.
var STUB_PORT = 3999;

function log(line) {
  document.getElementById('log').textContent += new Date().toLocaleTimeString() + '  ' + line + '\n';
}

function showInstallReference(attempt) {
  FloadAttribution.getInstallReference().then(function (result) {
    if (result.installReference) {
      document.getElementById('installReference').textContent = result.installReference;
    } else if ((attempt || 0) < 10) {
      setTimeout(function () { showInstallReference((attempt || 0) + 1); }, 300);
    }
  });
}

function setUserId() {
  return FloadAttribution.setUserId({ id: document.getElementById('userId').value })
    .then(function () { log('setUserId: ok'); })
    .catch(function (error) { log('setUserId: ' + error.message); });
}

document.addEventListener('deviceready', function () {
  var host = cordova.platformId === 'android' ? '10.0.2.2' : 'localhost';
  FloadAttribution.configure({ key: 'fload_pk_example', endpoint: 'http://' + host + ':' + STUB_PORT, logLevel: 'debug' })
    .then(function () { log('configure: ok (' + cordova.platformId + ')'); })
    .catch(function (error) { log('configure: ' + error.message); })
    .then(setUserId)
    .then(function () { showInstallReference(0); });
  document.getElementById('setUserId').addEventListener('click', setUserId);
}, false);
