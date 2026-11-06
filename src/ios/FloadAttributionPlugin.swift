import Cordova
import FloadAttribution
import Foundation

/// Cordova bridge over fload-attribution-ios. Each action maps one to one to
/// the Swift SDK; there is no logic here beyond reading the arguments. The SDK
/// returns at once and does its disk and network work on its own queue.
@objc(FloadAttributionPlugin)
final class FloadAttributionPlugin: CDVPlugin {
    @objc(configure:)
    func configure(_ command: CDVInvokedUrlCommand) {
        let options = command.argument(at: 0) as? [String: Any] ?? [:]
        let arguments = PluginArguments(
            key: options["key"] as? String,
            endpoint: options["endpoint"] as? String,
            logLevel: options["logLevel"] as? String
        )
        switch arguments.configuration() {
        case let .success(configuration):
            Fload.configure(key: configuration.key, options: configuration.options)
            send(CDVPluginResult(status: .ok), command)
        case let .failure(error):
            send(CDVPluginResult(status: .error, messageAs: error.message), command)
        }
    }

    @objc(setUserId:)
    func setUserId(_ command: CDVInvokedUrlCommand) {
        let options = command.argument(at: 0) as? [String: Any] ?? [:]
        guard let id = options["id"] as? String else {
            send(CDVPluginResult(status: .error, messageAs: "Fload: setUserId needs { id: \"…\" }"), command)
            return
        }
        Fload.setUserId(id)
        send(CDVPluginResult(status: .ok), command)
    }

    @objc(getInstallReference:)
    func getInstallReference(_ command: CDVInvokedUrlCommand) {
        let reference: Any = Fload.installReference ?? NSNull()
        send(CDVPluginResult(status: .ok, messageAs: ["installReference": reference]), command)
    }

    private func send(_ result: CDVPluginResult, _ command: CDVInvokedUrlCommand) {
        commandDelegate.send(result, callbackId: command.callbackId)
    }
}
