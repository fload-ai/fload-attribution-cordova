// Fload install attribution for Cordova apps. Every call returns a Promise and
// maps one to one to the native SDK (fload-attribution-ios on iOS,
// fload-attribution-android on Android). Use it after `deviceready`.
var exec = require('cordova/exec');

var LOG_LEVELS = ['none', 'error', 'warning', 'info', 'debug'];

function call(action, args) {
    return new Promise(function (resolve, reject) {
        exec(resolve, function (message) { reject(new Error(message)); }, 'FloadAttribution', action, args);
    });
}

function refuse(message) {
    return Promise.reject(new Error(message));
}

module.exports = {
    /**
     * Starts the SDK. Call it once, early, after `deviceready`.
     * @param {{ key: string, endpoint?: string, logLevel?: 'none'|'error'|'warning'|'info'|'debug' }} options
     * @returns {Promise<void>}
     */
    configure: function (options) {
        if (!options || typeof options.key !== 'string' || options.key.trim() === '') {
            return refuse('Fload: configure needs { key: "fload_pk_…" }');
        }
        if (options.endpoint !== undefined && typeof options.endpoint !== 'string') {
            return refuse('Fload: endpoint must be a URL string');
        }
        if (options.logLevel !== undefined && LOG_LEVELS.indexOf(options.logLevel) < 0) {
            return refuse('Fload: logLevel must be one of ' + LOG_LEVELS.join(', '));
        }
        var native = { key: options.key };
        if (options.endpoint !== undefined) native.endpoint = options.endpoint;
        if (options.logLevel !== undefined) native.logLevel = options.logLevel;
        return call('configure', [native]).then(function () {});
    },

    /**
     * Links your app's user id (for example RevenueCat's appUserID) to this install.
     * @param {{ id: string }} options
     * @returns {Promise<void>}
     */
    setUserId: function (options) {
        if (!options || typeof options.id !== 'string') {
            return refuse('Fload: setUserId needs { id: "…" }');
        }
        return call('setUserId', [{ id: options.id }]).then(function () {});
    },

    /**
     * This install's random reference, or null before configure has loaded the SDK's state.
     * @returns {Promise<{ installReference: string | null }>}
     */
    getInstallReference: function () {
        return call('getInstallReference', []).then(function (result) {
            return { installReference: (result && result.installReference) || null };
        });
    }
};
