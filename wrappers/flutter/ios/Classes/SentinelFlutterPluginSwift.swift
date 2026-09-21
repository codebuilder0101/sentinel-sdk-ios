import Flutter
import UIKit
import SentinelSDK

public class SentinelFlutterPluginSwift: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.sentinel.sdk/channel", binaryMessenger: registrar.messenger())
        let instance = SentinelFlutterPluginSwift()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            guard let args = call.arguments as? [String: Any],
                  let apiKey = args["apiKey"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "apiKey is required", details: nil))
                return
            }
            let env = args["environment"] as? String ?? "production"
            SentinelSDK.shared.initialize(apiKey: apiKey, environment: env)
            result(true)

        case "capture":
            guard let args = call.arguments as? [String: Any],
                  let userDataDict = args["userData"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "userData is required", details: nil))
                return
            }

            let fullName = userDataDict["fullName"] as? String ?? ""
            let documentId = userDataDict["documentId"] as? String
            let email = userDataDict["email"] as? String
            let phoneNumber = userDataDict["phoneNumber"] as? String
            let timeoutMs = args["timeoutMs"] as? Double ?? 5000.0
            let timeoutSeconds = timeoutMs / 1000.0

            let userInput = PersonalDataValidator.Input(
                fullName: fullName,
                documentId: documentId,
                email: email,
                phoneNumber: phoneNumber
            )

            let config = SentinelSDK.CaptureConfiguration(
                userData: userInput,
                locationTimeoutSeconds: timeoutSeconds,
                wrapper: "flutter"
            )

            Task {
                do {
                    let jsonString = try await SentinelSDK.shared.captureJSON(configuration: config)
                    DispatchQueue.main.async {
                        result(jsonString)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "CAPTURE_ERROR", message: error.localizedDescription, details: nil))
                    }
                }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
