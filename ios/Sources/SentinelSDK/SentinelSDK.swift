import Foundation

/// Primary facade for the Sentinel SDK on iOS.
public final class SentinelSDK {

    public static let shared = SentinelSDK()
    public static let version = "1.0.0"

    private var apiKey: String?
    private var isInitialized = false

    private let personalDataValidator = PersonalDataValidator()
    private let deviceDataCollector = DeviceDataCollector()
    private let locationCollector = LocationCollector()
    private let appDetectionCollector = AppDetectionCollector()

    private init() {}

    /// Initializes the Sentinel SDK with client API credentials.
    public func initialize(apiKey: String) {
        self.apiKey = apiKey
        self.isInitialized = true
    }

    /// Configuration options for data capture.
    public struct CaptureConfiguration {
        public let userData: PersonalDataValidator.Input
        public let locationTimeoutSeconds: TimeInterval
        public let wrapper: String

        public init(
            userData: PersonalDataValidator.Input,
            locationTimeoutSeconds: TimeInterval = 5.0,
            wrapper: String = "native"
        ) {
            self.userData = userData
            self.locationTimeoutSeconds = locationTimeoutSeconds
            self.wrapper = wrapper
        }
    }

    /// Captures all required telemetry, runs validation, and generates a signed payload.
    public func capture(configuration: CaptureConfiguration) async -> SentinelPayload {
        let startTime = Date()

        // 1. Validate personal data
        let userData = personalDataValidator.validate(input: configuration.userData)

        // 2. Collect device telemetry
        let deviceData = deviceDataCollector.collect()

        // 3. Collect location
        let locationData = await locationCollector.collectLocation(timeoutSeconds: configuration.locationTimeoutSeconds)

        // 4. Scan targeted applications on main actor
        let installedApps = await MainActor.run {
            self.appDetectionCollector.scan()
        }

        let captureDurationMs = Int(Date().timeIntervalSince(startTime) * 1000)

        // 5. Build metadata
        #if os(iOS)
        let osVersion = UIDevice.current.systemVersion
        #else
        let osVersion = "unknown"
        #endif

        let metadata = SentinelMetadata(
            sdkVersion: SentinelSDK.version,
            platform: "ios",
            osVersion: osVersion,
            wrapper: configuration.wrapper,
            timestamp: ISO8601DateFormatter().string(from: startTime),
            captureDurationMs: captureDurationMs
        )

        // 6. Assemble pre-security payload for hashing
        let unsignedPayload = PreSecurityPayload(
            metadata: metadata,
            userData: userData,
            deviceData: deviceData,
            locationData: locationData,
            installedApps: installedApps
        )

        let signer = PayloadSigner(secretKey: apiKey)
        let payloadData = (try? JSONEncoder().encode(unsignedPayload)) ?? Data()
        let securityData = signer.sign(data: payloadData)

        return SentinelPayload(
            metadata: metadata,
            userData: userData,
            deviceData: deviceData,
            locationData: locationData,
            installedApps: installedApps,
            security: securityData
        )
    }

    /// Captures and serializes the payload directly to a JSON string.
    public func captureJSON(configuration: CaptureConfiguration) async throws -> String {
        let payload = await capture(configuration: configuration)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "SentinelSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode JSON"])
        }
        return jsonString
    }
}

private struct PreSecurityPayload: Codable {
    let metadata: SentinelMetadata
    let userData: SentinelUserData
    let deviceData: SentinelDeviceData
    let locationData: SentinelLocationData
    let installedApps: SentinelInstalledApps

    enum CodingKeys: String, CodingKey {
        case metadata
        case userData = "user_data"
        case deviceData = "device_data"
        case locationData = "location_data"
        case installedApps = "installed_apps"
    }
}
