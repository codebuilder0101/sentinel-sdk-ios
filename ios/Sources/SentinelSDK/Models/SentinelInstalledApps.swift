import Foundation

/// Detection results for targeted applications (betting and gambling apps screening).
public struct SentinelInstalledApps: Codable {
    public let scanStrategy: String
    public let totalTargetsScanned: Int
    public let totalDetected: Int
    public let riskLevel: String
    public let hasBettingApps: Bool
    public let detectedApps: [SentinelDetectedApp]
    public let unresolvedSchemesCount: Int

    enum CodingKeys: String, CodingKey {
        case scanStrategy = "scan_strategy"
        case totalTargetsScanned = "total_targets_scanned"
        case totalDetected = "total_detected"
        case riskLevel = "risk_level"
        case hasBettingApps = "has_betting_apps"
        case detectedApps = "detected_apps"
        case unresolvedSchemesCount = "unresolved_schemes_count"
    }

    public init(
        scanStrategy: String = "targeted_scheme_queries",
        totalTargetsScanned: Int,
        totalDetected: Int,
        riskLevel: String,
        hasBettingApps: Bool,
        detectedApps: [SentinelDetectedApp],
        unresolvedSchemesCount: Int
    ) {
        self.scanStrategy = scanStrategy
        self.totalTargetsScanned = totalTargetsScanned
        self.totalDetected = totalDetected
        self.riskLevel = riskLevel
        self.hasBettingApps = hasBettingApps
        self.detectedApps = detectedApps
        self.unresolvedSchemesCount = unresolvedSchemesCount
    }
}

public struct SentinelDetectedApp: Codable {
    public let targetId: String
    public let appName: String
    public let category: String
    public let detectionIdentifier: String
    public let detectionMethod: String
    public let isDetected: Bool

    enum CodingKeys: String, CodingKey {
        case targetId = "target_id"
        case appName = "app_name"
        case category
        case detectionIdentifier = "detection_identifier"
        case detectionMethod = "detection_method"
        case isDetected = "is_detected"
    }

    public init(
        targetId: String,
        appName: String,
        category: String = "gambling_betting",
        detectionIdentifier: String,
        detectionMethod: String = "can_open_url_scheme",
        isDetected: Bool
    ) {
        self.targetId = targetId
        self.appName = appName
        self.category = category
        self.detectionIdentifier = detectionIdentifier
        self.detectionMethod = detectionMethod
        self.isDetected = isDetected
    }
}
