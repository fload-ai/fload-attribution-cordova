package com.fload.attribution.cordova;

import com.fload.attribution.FloadLogLevel;
import com.fload.attribution.FloadWrapper;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Plain-JVM checks of the Android argument rules; run by scripts/test-android.sh. */
public final class PluginArgumentsTest {
    private static int failures = 0;

    private static void check(boolean ok, String name) {
        System.out.println((ok ? "ok   " : "FAIL ") + name);
        if (!ok) failures++;
    }

    /** This package's version, from package.json (the script runs from the package root). */
    private static String packageVersion() throws IOException {
        String json = new String(Files.readAllBytes(Paths.get("package.json")), StandardCharsets.UTF_8);
        Matcher m = Pattern.compile("\"version\"\\s*:\\s*\"([^\"]+)\"").matcher(json);
        if (!m.find()) throw new IOException("package.json has no version");
        return m.group(1);
    }

    public static void main(String[] args) throws IOException {
        PluginArguments.Configuration plain = PluginArguments.configuration("fload_pk_abc", null, null);
        check(plain.ok() && plain.key.equals("fload_pk_abc"), "key passes through");
        check(plain.ok() && plain.options.getEndpoint().equals("https://ingest.fload.com"), "default endpoint is production");
        check(plain.ok() && plain.options.getLogLevel() == FloadLogLevel.WARNING, "default log level is warning");

        check(!PluginArguments.configuration(null, null, null).ok(), "missing key is refused");
        check(!PluginArguments.configuration("  ", null, null).ok(), "blank key is refused");

        PluginArguments.Configuration local = PluginArguments.configuration("k", "http://10.0.2.2:3999", "debug");
        check(local.ok() && local.options.getEndpoint().equals("http://10.0.2.2:3999"), "endpoint override");
        check(local.ok() && local.options.getLogLevel() == FloadLogLevel.DEBUG, "log level override");

        // The plugin names itself on every request (sdk.wrapper) with this package's own version.
        String version = packageVersion();
        for (PluginArguments.Configuration c : new PluginArguments.Configuration[] {plain, local}) {
            FloadWrapper wrapper = c.ok() ? c.options.getWrapper() : null;
            check(wrapper != null && wrapper.getName().equals("cordova") && wrapper.getVersion().equals(version),
                    "options name the wrapper cordova " + version + " (" + (c == plain ? "defaults" : "overrides") + ")");
        }

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
