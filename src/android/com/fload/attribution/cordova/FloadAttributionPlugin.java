package com.fload.attribution.cordova;

import com.fload.attribution.Fload;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Cordova bridge over fload-attribution-android. Each action maps one to one to
 * the Kotlin SDK; there is no logic here beyond reading the arguments. The SDK
 * returns at once and does its disk and network work on its own thread.
 */
public class FloadAttributionPlugin extends CordovaPlugin {

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callback) throws JSONException {
        JSONObject options = args.optJSONObject(0);
        if (options == null) options = new JSONObject();
        switch (action) {
            case "configure":
                configure(options, callback);
                return true;
            case "setUserId":
                setUserId(options, callback);
                return true;
            case "getInstallReference":
                JSONObject result = new JSONObject();
                String reference = Fload.getInstallReference();
                result.put("installReference", reference != null ? reference : JSONObject.NULL);
                callback.success(result);
                return true;
            default:
                return false;
        }
    }

    private void configure(JSONObject options, CallbackContext callback) {
        PluginArguments.Configuration configuration = PluginArguments.configuration(
                string(options, "key"), string(options, "endpoint"), string(options, "logLevel"));
        if (!configuration.ok()) {
            callback.error(configuration.error);
            return;
        }
        Fload.configure(cordova.getContext(), configuration.key, configuration.options);
        callback.success();
    }

    private void setUserId(JSONObject options, CallbackContext callback) {
        String id = string(options, "id");
        if (id == null) {
            callback.error("Fload: setUserId needs { id: \"…\" }");
            return;
        }
        Fload.setUserId(id);
        callback.success();
    }

    /** The string at `name`, or null when it is missing, null or not a string. */
    private static String string(JSONObject options, String name) {
        Object value = options.opt(name);
        return value instanceof String ? (String) value : null;
    }
}
