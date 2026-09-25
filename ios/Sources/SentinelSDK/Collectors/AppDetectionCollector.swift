import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Targeted application screening engine for iOS (respecting Apple Sandbox and canOpenURL policies).
public final class AppDetectionCollector {

    public struct TargetApp {
        public let id: String
        public let name: String
        public let scheme: String?
        public let category: String

        public init(id: String, name: String, scheme: String?, category: String = "gambling_betting") {
            self.id = id
            self.name = name
            self.scheme = scheme
            self.category = category
        }
    }

    /// Master target catalog of top betting and gambling applications
    public static let defaultTargets: [TargetApp] = [
        TargetApp(id: "bet365", name: "bet365", scheme: "bet365"),
        TargetApp(id: "superbets", name: "Superbet", scheme: "superbet"),
        TargetApp(id: "sportybet", name: "SportyBet", scheme: "sportybet"),
        TargetApp(id: "betano", name: "Betano", scheme: "betano"),
        TargetApp(id: "novibet", name: "Novibet", scheme: "novibet"),
        TargetApp(id: "sportingbet", name: "Sportingbet Livescore", scheme: "sportingbet"),
        TargetApp(id: "betfair", name: "Betfair", scheme: "betfair"),
        TargetApp(id: "betsson", name: "Betsson", scheme: "betsson"),
        TargetApp(id: "rivalo", name: "Rivalo", scheme: "rivalo"),
        TargetApp(id: "onexbet", name: "1xBet", scheme: "onexbet"),
        TargetApp(id: "pinnacle", name: "Pinnacle Sports", scheme: "pinnacle"),
        TargetApp(id: "pokerstars", name: "PokerStars", scheme: "pokerstars"),
        TargetApp(id: "betway", name: "Betway", scheme: "betway"),
        TargetApp(id: "bwin", name: "bwin Sportsbook", scheme: "bwin"),
        TargetApp(id: "unibet", name: "Unibet", scheme: "unibet"),
        TargetApp(id: "williamhill", name: "William Hill", scheme: "williamhill"),
        TargetApp(id: "paddypower", name: "Paddy Power", scheme: "paddypower"),
        TargetApp(id: "ladbrokes", name: "Ladbrokes", scheme: "ladbrokes"),
        TargetApp(id: "coral", name: "Coral Sports", scheme: "coral"),
        TargetApp(id: "dafabet", name: "Dafabet", scheme: "dafabet"),
        TargetApp(id: "stake", name: "Stake", scheme: "stake"),
        TargetApp(id: "galera_bet", name: "Galera.bet", scheme: nil),
        TargetApp(id: "pixbet", name: "Pixbet", scheme: nil),
        TargetApp(id: "estrelabet", name: "EstrelaBet", scheme: nil),
        TargetApp(id: "blaze", name: "Blaze", scheme: nil)
    ]

    public init() {}

    @MainActor
    public func scan(targets: [TargetApp] = AppDetectionCollector.defaultTargets) -> SentinelInstalledApps {
        var detectedList: [SentinelDetectedApp] = []
        var unresolvedCount = 0

        for target in targets {
            guard let scheme = target.scheme, !scheme.isEmpty else {
                unresolvedCount += 1
                continue
            }

            let schemeUrlString = "\(scheme)://"
            guard let url = URL(string: schemeUrlString) else {
                unresolvedCount += 1
                continue
            }

            #if os(iOS)
            let canOpen = UIApplication.shared.canOpenURL(url)
            if canOpen {
                detectedList.append(SentinelDetectedApp(
                    targetId: target.id,
                    appName: target.name,
                    category: target.category,
                    detectionIdentifier: schemeUrlString,
                    detectionMethod: "can_open_url_scheme",
                    isDetected: true
                ))
            }
            #endif
        }

        let hasBetting = !detectedList.isEmpty
        let riskLevel = hasBetting ? "FLAGGED" : "CLEAN"

        return SentinelInstalledApps(
            scanStrategy: "targeted_scheme_queries",
            totalTargetsScanned: targets.count,
            totalDetected: detectedList.count,
            riskLevel: riskLevel,
            hasBettingApps: hasBetting,
            detectedApps: detectedList,
            unresolvedSchemesCount: unresolvedCount
        )
    }
}
