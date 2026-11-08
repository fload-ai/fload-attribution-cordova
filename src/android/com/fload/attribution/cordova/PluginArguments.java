package com.fload.attribution.cordova;

import com.fload.attribution.FloadLogLevel;
import com.fload.attribution.FloadOptions;
import com.fload.attribution.FloadWrapper;

import java.net.URI;
import java.util.HashMap;
import java.util.Map;

/** The plugin's argument rules, kept free of Cordova so they can be unit tested. */
final class PluginArguments {
    /**
     * This plugin as every request names it (`sdk.wrapper`). Java cannot read
     * package.json at build time, so the version is a constant;
     * test/versions.test.js and PluginArgumentsTest hold it equal to package.json.
     */
    static final String WRAPPER_NAME = "cordova";
    static final String WRAPPER_VERSION = "1.1.0";

    static final Map<String, FloadLogLevel> LOG_LEVELS = new HashMap<>();

    static {
        LOG_LEVELS.put("none", FloadLogLevel.NONE);
        LOG_LEVELS.put("error", FloadLogLevel.ERROR);
        LOG_LEVELS.put("warning", FloadLogLevel.WARNING);
        LOG_LEVELS.put("info", FloadLogLevel.INFO);
        LOG_LEVELS.put("debug", FloadLogLevel.DEBUG);
    }

    /** A configure call that passed the rules, or the reason it did not. */
    static final class Configuration {
        final String key;
        final FloadOptions options;
        final String error;

        private Configuration(String key, FloadOptions options, String error) {
            this.key = key;
            this.options = options;
            this.error = error;
        }

        boolean ok() {
            return error == null;
        }
    }

    private PluginArguments() {}

    static Configuration configuration(String key, String endpoint, String logLevel) {
        if (key == null || key.trim().isEmpty()) {
            return failure("Fload: configure needs { key: \"fload_pk_…\" }");
        }
        FloadOptions defaults = new FloadOptions();
        String resolvedEndpoint = endpoint != null ? endpoint : defaults.getEndpoint();
        if (!isHttpUrl(resolvedEndpoint)) {
            return failure("Fload: endpoint must be an http(s) URL");
        }
        FloadLogLevel level = defaults.getLogLevel();
        if (logLevel != null) {
            level = LOG_LEVELS.get(logLevel);
            if (level == null) {
                return failure("Fload: logLevel must be one of none, error, warning, info, debug");
            }
        }
        FloadWrapper wrapper = new FloadWrapper(WRAPPER_NAME, WRAPPER_VERSION);
        return new Configuration(key, new FloadOptions(resolvedEndpoint, level, wrapper), null);
    }

    private static Configuration failure(String message) {
        return new Configuration(null, null, message);
    }

    private static boolean isHttpUrl(String value) {
        try {
            URI uri = new URI(value);
            String scheme = uri.getScheme();
            String host = uri.getHost();
            return ("https".equals(scheme) || "http".equals(scheme)) && host != null && !host.isEmpty();
        } catch (Exception e) {
            return false;
        }
    }
}
