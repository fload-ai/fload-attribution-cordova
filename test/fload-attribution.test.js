// The JS layer (www/fload-attribution.js) with cordova/exec replaced by a fake:
// argument checks, what reaches the native side, and promise results.
const test = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');
const path = require('node:path');

function load(nativeResult) {
  const calls = [];
  const exec = (success, failure, service, action, args) => {
    calls.push({ service, action, args });
    const result = nativeResult(action, args);
    if (result instanceof Error) failure(result.message);
    else success(result);
  };
  const originalResolve = Module._resolveFilename;
  Module._resolveFilename = function (request, ...rest) {
    if (request === 'cordova/exec') return 'cordova/exec';
    return originalResolve.call(this, request, ...rest);
  };
  require.cache['cordova/exec'] = { id: 'cordova/exec', filename: 'cordova/exec', loaded: true, exports: exec };
  const file = path.join(__dirname, '..', 'www', 'fload-attribution.js');
  delete require.cache[file];
  const plugin = require(file);
  Module._resolveFilename = originalResolve;
  return { plugin, calls };
}

test('configure sends the key and only the options given', async () => {
  const { plugin, calls } = load(() => 'OK');
  await plugin.configure({ key: 'fload_pk_abc' });
  await plugin.configure({ key: 'fload_pk_abc', endpoint: 'http://localhost:3999', logLevel: 'debug' });
  assert.deepEqual(calls, [
    { service: 'FloadAttribution', action: 'configure', args: [{ key: 'fload_pk_abc' }] },
    { service: 'FloadAttribution', action: 'configure', args: [{ key: 'fload_pk_abc', endpoint: 'http://localhost:3999', logLevel: 'debug' }] },
  ]);
});

test('configure refuses bad arguments without calling native', async () => {
  const { plugin, calls } = load(() => 'OK');
  await assert.rejects(plugin.configure(), /needs \{ key/);
  await assert.rejects(plugin.configure({ key: '  ' }), /needs \{ key/);
  await assert.rejects(plugin.configure({ key: 'k', endpoint: 3 }), /endpoint/);
  await assert.rejects(plugin.configure({ key: 'k', logLevel: 'verbose' }), /logLevel/);
  assert.equal(calls.length, 0);
});

test('a native error rejects with its message', async () => {
  const { plugin } = load(() => new Error('Fload: endpoint must be an http(s) URL'));
  await assert.rejects(plugin.configure({ key: 'k', endpoint: 'ftp://x' }), /http\(s\) URL/);
});

test('setUserId passes the id', async () => {
  const { plugin, calls } = load(() => 'OK');
  await plugin.setUserId({ id: 'user_123' });
  await assert.rejects(plugin.setUserId({}), /needs \{ id/);
  assert.deepEqual(calls, [{ service: 'FloadAttribution', action: 'setUserId', args: [{ id: 'user_123' }] }]);
});

test('getInstallReference returns the reference or null', async () => {
  const withRef = load(() => ({ installReference: 'ref-1234' }));
  assert.deepEqual(await withRef.plugin.getInstallReference(), { installReference: 'ref-1234' });
  const without = load(() => ({ installReference: null }));
  assert.deepEqual(await without.plugin.getInstallReference(), { installReference: null });
});
