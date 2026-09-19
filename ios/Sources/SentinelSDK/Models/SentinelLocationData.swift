import Foundation

/// Geolocation data captured with high precision and anti-spoofing flags.
public struct SentinelLocationData: Codable {
    public let status: String
    public let permissionStatus: String
    public let coordinates: SentinelCoordinates
    public let timestamp: String
    public let isMockLocation: Bool

    enum CodingKeys: String, CodingKey {
        case status
        case permissionStatus = "permission_status"
        case coordinates
        case timestamp
        case isMockLocation = "is_mock_location"
    }

    public init(
        status: String,
        permissionStatus: String,
        coordinates: SentinelCoordinates,
        timestamp: String,
        isMockLocation: Bool
    ) {
        self.status = status
        self.permissionStatus = permissionStatus
        self.coordinates = coordinates
        self.timestamp = timestamp
        self.isMockLocation = isMockLocation
    }
}

public struct SentinelCoordinates: Codable {
    public let latitude: Double
    public let longitude: Double
    public let accuracyMeters: Double
    public let altitudeMeters: Double?
    public let altitudeAccuracyMeters: Double?
    public let headingDegrees: Double?
    public let speedMps: Double?

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case accuracyMeters = "accuracy_meters"
        case altitudeMeters = "altitude_meters"
        case altitudeAccuracyMeters = "altitude_accuracy_meters"
        case headingDegrees = "heading_degrees"
        case speedMps = "speed_mps"
    }

    public init(
        latitude: Double,
        longitude: Double,
        accuracyMeters: Double,
        altitudeMeters: Double? = nil,
        altitudeAccuracyMeters: Double? = nil,
        headingDegrees: Double? = nil,
        speedMps: Double? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracyMeters = accuracyMeters
        self.altitudeMeters = altitudeMeters
        self.altitudeAccuracyMeters = altitudeAccuracyMeters
        self.headingDegrees = headingDegrees
        self.speedMps = speedMps
    }
}
