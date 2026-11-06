package com.fload.attribution.cordova;

import com.fload.attribution.FloadLogLevel;

/** Plain-JVM checks of the Android argument rules; run by scripts/test-android.sh. */
public final class PluginArgumentsTest {
    private static int failures = 0;

    private static void check(boolean ok, String name) {
        System.out.println((ok ? "ok   " : "FAIL ") + name);
        if (!ok) failures++;
    }

    public static void main(String[] args) {
        PluginArguments.Configuration plain = PluginArguments.configuration("fload_pk_abc", null, null);
        check(plain.ok() && plain.key.equals("fload_pk_abc"), "key passes through");
        check(plain.ok() && plain.options.getEndpoint().equals("https://ingest.fload.com"), "default endpoint is production");
        check(plain.ok() && plain.options.getLogLevel() == FloadLogLevel.WARNING, "default log level is warning");

        check(!PluginArguments.configuration(null, null, null).ok(), "missing key is refused");
        check(!PluginArguments.configuration("  ", null, null).ok(), "blank key is refused");

        PluginArguments.Configuration local = PluginArguments.configuration("k", "http://10.0.2.2:3999", "debug");
        check(local.ok() && local.options.getEndpoint().equals("http://10.0.2.2:3999"), "endpoint override");
        check(local.ok() && local.options.getLogLevel() == FloadLogLevel.DEBUG, "log level override");

        check(!PluginArguments.configuration("k", "ftp://x", null).ok(), "non-http endpoint is refused");
        check(!PluginArguments.configuration("k", "not a url", null).ok(), "bad endpoint is refused");
        check(!PluginArguments.configuration("k", null, "verbose").ok(), "unknown log level is refused");
        for (String name : new String[] {"none", "error", "warning", "info", "debug"}) {
            check(PluginArguments.configuration("k", null, name).ok(), "log level " + name + " is accepted");
        }

        System.out.println(failures == 0 ? "all passed" : failures + " failed");
        System.exit(failures == 0 ? 0 : 1);
    }
}
