import Foundation

/// Top-level standardized payload captured by Sentinel SDK.
public struct SentinelPayload: Codable {
    public let metadata: SentinelMetadata
    public let userData: SentinelUserData
    public let deviceData: SentinelDeviceData
    public let locationData: SentinelLocationData
    public let installedApps: SentinelInstalledApps
    public let security: SentinelSecurityData

    enum CodingKeys: String, CodingKey {
        case metadata
        case userData = "user_data"
        case deviceData = "device_data"
        case locationData = "location_data"
        case installedApps = "installed_apps"
        case security
    }

    public init(
        metadata: SentinelMetadata,
        userData: SentinelUserData,
        deviceData: SentinelDeviceData,
        locationData: SentinelLocationData,
        installedApps: SentinelInstalledApps,
        security: SentinelSecurityData
    ) {
        self.metadata = metadata
        self.userData = userData
        self.deviceData = deviceData
        self.locationData = locationData
        self.installedApps = installedApps
        self.security = security
    }
}

public struct SentinelMetadata: Codable {
    public let sdkVersion: String
    public let platform: String
    public let osVersion: String
    public let wrapper: String
    public let sessionId: String
    public let requestId: String
    public let timestamp: String
    public let captureDurationMs: Int

    enum CodingKeys: String, CodingKey {
        case sdkVersion = "sdk_version"
        case platform
        case osVersion = "os_version"
        case wrapper
        case sessionId = "session_id"
        case requestId = "request_id"
        case timestamp
        case captureDurationMs = "capture_duration_ms"
    }

    public init(
        sdkVersion: String = "1.0.0",
        platform: String = "ios",
        osVersion: String,
        wrapper: String = "native",
        sessionId: String = UUID().uuidString,
        requestId: String = "req_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased(),
        timestamp: String,
        captureDurationMs: Int
    ) {
        self.sdkVersion = sdkVersion
        self.platform = platform
        self.osVersion = osVersion
        self.wrapper = wrapper
        self.sessionId = sessionId
        self.requestId = requestId
        self.timestamp = timestamp
        self.captureDurationMs = captureDurationMs
    }
}
