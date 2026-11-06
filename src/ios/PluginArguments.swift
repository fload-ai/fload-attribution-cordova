import Foundation
#if canImport(FloadAttribution)
import FloadAttribution
#endif

/// The plugin's argument rules, kept free of Capacitor so they can be unit tested.
struct PluginArguments {
    struct Configuration {
        let key: String
        let options: FloadOptions
    }

    struct Failure: Error, Equatable {
        let message: String
    }

    var key: String?
    var endpoint: String?
    var logLevel: String?

    func configuration() -> Result<Configuration, Failure> {
        guard let key, !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(Failure(message: "Fload: configure needs { key: \"fload_pk_…\" }"))
        }
        var options = FloadOptions()
        if let endpoint {
            guard let url = URL(string: endpoint), url.scheme == "https" || url.scheme == "http" else {
                return .failure(Failure(message: "Fload: endpoint must be an http(s) URL"))
            }
            options.endpoint = url
        }
        if let logLevel {
            guard let level = Self.logLevels[logLevel] else {
                return .failure(Failure(message: "Fload: logLevel must be one of none, error, warning, info, debug"))
            }
            options.logLevel = level
        }
        return .success(Configuration(key: key, options: options))
    }

    static let logLevels: [String: FloadLogLevel] = [
        "none": .none,
        "error": .error,
        "warning": .warning,
        "info": .info,
        "debug": .debug,
    ]
}
