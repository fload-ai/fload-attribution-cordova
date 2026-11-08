// Host-side checks of the plugin's argument rules, compiled with the pinned
// fload-attribution-ios sources by scripts/host-test-ios.sh and run from the
// package root (they read package.json). They need no Xcode or simulator, only
// a Swift toolchain, so they run on any Mac and in CI before the iOS build.
import Foundation

var failures = 0
func check(_ condition: Bool, _ name: String) {
    if condition { print("ok   \(name)") } else { failures += 1; print("FAIL \(name)") }
}

func configuration(_ key: String?, _ endpoint: String? = nil, _ logLevel: String? = nil) -> Result<PluginArguments.Configuration, PluginArguments.Failure> {
    PluginArguments(key: key, endpoint: endpoint, logLevel: logLevel).configuration()
}

if case let .success(c) = configuration("fload_pk_abc") {
    check(c.key == "fload_pk_abc", "key passes through")
    check(c.options.endpoint == URL(string: "https://ingest.fload.com")!, "default endpoint is production")
    check(c.options.logLevel == .warning, "default log level is warning")
} else { check(false, "plain key configures") }

check((try? configuration(nil).get()) == nil, "missing key is refused")
check((try? configuration("   ").get()) == nil, "blank key is refused")

if case let .success(c) = configuration("fload_pk_abc", "http://localhost:3001", "debug") {
    check(c.options.endpoint == URL(string: "http://localhost:3001")!, "endpoint override")
    check(c.options.logLevel == .debug, "log level override")
} else { check(false, "endpoint and log level configure") }

// The plugin names itself on every request (sdk.wrapper) with this package's own version.
let package = try! JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: "package.json"))) as! [String: Any]
let packageVersion = package["version"] as! String
for (name, result) in [("default options", configuration("k")), ("overridden options", configuration("k", "http://localhost:3001", "debug"))] {
    if case let .success(c) = result {
        check(c.options.wrapper == FloadWrapper(name: "cordova", version: packageVersion), "\(name) name the wrapper cordova \(packageVersion)")
    } else { check(false, "\(name) configure") }
}

check((try? configuration("k", "ftp://x").get()) == nil, "non-http endpoint is refused")
check((try? configuration("k", nil, "verbose").get()) == nil, "unknown log level is refused")
for name in ["none", "error", "warning", "info", "debug"] {
    check((try? configuration("k", nil, name).get()) != nil, "log level \(name) is accepted")
}

if failures > 0 { print("\(failures) failed"); exit(1) }
print("all passed")
