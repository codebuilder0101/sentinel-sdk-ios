import Foundation

/// Device telemetry and telephony attributes.
public struct SentinelDeviceData: Codable {
    public let deviceIdentifier: String
    public let model: String
    public let manufacturer: String
    public let brand: String
    public let locale: String
    public let timezone: String
    public let screenResolution: String
    public let batteryLevel: Float
    public let batteryState: String
    public let isJailbrokenOrRooted: Bool
    public let isEmulator: Bool
    public let telephony: SentinelTelephonyData

    enum CodingKeys: String, CodingKey {
        case deviceIdentifier = "device_identifier"
        case model
        case manufacturer
        case brand
        case locale
        case timezone
        case screenResolution = "screen_resolution"
        case batteryLevel = "battery_level"
        case batteryState = "battery_state"
        case isJailbrokenOrRooted = "is_jailbroken_or_rooted"
        case isEmulator = "is_emulator"
        case telephony
    }

    public init(
        deviceIdentifier: String,
        model: String,
        manufacturer: String,
        brand: String,
        locale: String,
        timezone: String,
        screenResolution: String,
        batteryLevel: Float,
        batteryState: String,
        isJailbrokenOrRooted: Bool,
        isEmulator: Bool,
        telephony: SentinelTelephonyData
    ) {
        self.deviceIdentifier = deviceIdentifier
        self.model = model
        self.manufacturer = manufacturer
        self.brand = brand
        self.locale = locale
        self.timezone = timezone
        self.screenResolution = screenResolution
        self.batteryLevel = batteryLevel
        self.batteryState = batteryState
        self.isJailbrokenOrRooted = isJailbrokenOrRooted
        self.isEmulator = isEmulator
        self.telephony = telephony
    }
}

public struct SentinelTelephonyData: Codable {
    public let carrierName: String
    public let mobileCountryCode: String
    public let mobileNetworkCode: String
    public let isoCountryCode: String
    public let networkType: String
    public let isSimReady: Bool
    public let simOperatorName: String?

    enum CodingKeys: String, CodingKey {
        case carrierName = "carrier_name"
        case mobileCountryCode = "mobile_country_code"
        case mobileNetworkCode = "mobile_network_code"
        case isoCountryCode = "iso_country_code"
        case networkType = "network_type"
        case isSimReady = "is_sim_ready"
        case simOperatorName = "sim_operator_name"
    }

    public init(
        carrierName: String,
        mobileCountryCode: String,
        mobileNetworkCode: String,
        isoCountryCode: String,
        networkType: String,
        isSimReady: Bool,
        simOperatorName: String? = nil
    ) {
        self.carrierName = carrierName
        self.mobileCountryCode = mobileCountryCode
        self.mobileNetworkCode = mobileNetworkCode
        self.isoCountryCode = isoCountryCode
        self.networkType = networkType
        self.isSimReady = isSimReady
        self.simOperatorName = simOperatorName
    }
}
