import Foundation
import SentinelSDK

@objc(SentinelReactNativeBridge)
public class SentinelReactNativeBridge: NSObject {

    @objc public static let shared = SentinelReactNativeBridge()

    @objc public func initialize(
        apiKey: String,
        environment: String,
        resolver resolve: @escaping (Any?) -> Void,
        rejecter reject: @escaping (String?, String?, Error?) -> Void
    ) {
        SentinelSDK.shared.initialize(apiKey: apiKey, environment: environment)
        resolve(true)
    }

    @objc public func capture(
        options: [String: Any],
        resolver resolve: @escaping (Any?) -> Void,
        rejecter reject: @escaping (String?, String?, Error?) -> Void
    ) {
        let userDataDict = options["userData"] as? [String: Any] ?? [:]
        let fullName = userDataDict["fullName"] as? String ?? ""
        let documentId = userDataDict["documentId"] as? String
        let email = userDataDict["email"] as? String
        let phoneNumber = userDataDict["phoneNumber"] as? String
        let timeoutMs = options["timeoutMs"] as? Double ?? 5000.0
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
            wrapper: "react-native"
        )

        Task {
            do {
                let jsonString = try await SentinelSDK.shared.captureJSON(configuration: config)
                if let data = jsonString.data(using: .utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                    DispatchQueue.main.async {
                        resolve(jsonObject)
                    }
                } else {
                    DispatchQueue.main.async {
                        resolve(jsonString)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    reject("CAPTURE_ERROR", error.localizedDescription, error)
                }
            }
        }
    }
}
