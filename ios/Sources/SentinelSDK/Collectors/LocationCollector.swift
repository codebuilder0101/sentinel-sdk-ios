import Foundation
#if canImport(CoreLocation)
import CoreLocation
#endif

/// Collects high-accuracy GPS coordinates and location telemetry with mock-detection.
public final class LocationCollector: NSObject {

    public override init() {
        super.init()
    }

    public func collectLocation(timeoutSeconds: TimeInterval = 5.0) async -> SentinelLocationData {
        #if canImport(CoreLocation)
        let authStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            authStatus = CLLocationManager().authorizationStatus
        } else {
            authStatus = CLLocationManager.authorizationStatus()
        }

        let statusString = authorizationStatusString(authStatus)

        guard authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways else {
            return SentinelLocationData(
                status: "PERMISSION_DENIED",
                permissionStatus: statusString,
                coordinates: SentinelCoordinates(latitude: 0.0, longitude: 0.0, accuracyMeters: -1.0),
                timestamp: ISO8601DateFormatter().string(from: Date()),
                isMockLocation: false
            )
        }

        let delegate = SingleLocationDelegate()
        return await withCheckedContinuation { continuation in
            delegate.onComplete = { location in
                let timestampStr = ISO8601DateFormatter().string(from: location?.timestamp ?? Date())
                if let loc = location {
                    let isMock: Bool
                    if #available(iOS 15.0, *) {
                        isMock = loc.sourceInformation?.isSimulatedBySoftware ?? false
                    } else {
                        isMock = false
                    }

                    let coords = SentinelCoordinates(
                        latitude: loc.coordinate.latitude,
                        longitude: loc.coordinate.longitude,
                        accuracyMeters: loc.horizontalAccuracy,
                        altitudeMeters: loc.altitude,
                        altitudeAccuracyMeters: loc.verticalAccuracy >= 0 ? loc.verticalAccuracy : nil,
                        headingDegrees: loc.course >= 0 ? loc.course : nil,
                        speedMps: loc.speed >= 0 ? loc.speed : nil
                    )

                    continuation.resume(returning: SentinelLocationData(
                        status: "SUCCESS",
                        permissionStatus: statusString,
                        coordinates: coords,
                        timestamp: timestampStr,
                        isMockLocation: isMock
                    ))
                } else {
                    continuation.resume(returning: SentinelLocationData(
                        status: "TIMEOUT",
                        permissionStatus: statusString,
                        coordinates: SentinelCoordinates(latitude: 0.0, longitude: 0.0, accuracyMeters: -1.0),
                        timestamp: timestampStr,
                        isMockLocation: false
                    ))
                }
            }
            delegate.start(timeoutSeconds: timeoutSeconds)
        }
        #else
        return SentinelLocationData(
            status: "UNAVAILABLE",
            permissionStatus: "unavailable",
            coordinates: SentinelCoordinates(latitude: 0.0, longitude: 0.0, accuracyMeters: -1.0),
            timestamp: ISO8601DateFormatter().string(from: Date()),
            isMockLocation: false
        )
        #endif
    }

    #if canImport(CoreLocation)
    public func authorizationStatusString(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways: return "authorized_always"
        case .authorizedWhenInUse: return "authorized_when_in_use"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .notDetermined: return "not_determined"
        @unknown default: return "unknown"
        }
    }
    #endif
}

#if canImport(CoreLocation)
private final class SingleLocationDelegate: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var onComplete: ((CLLocation?) -> Void)?
    private var timer: Timer?
    private var isCompleted = false

    func start(timeoutSeconds: TimeInterval) {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.requestLocation()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: timeoutSeconds, repeats: false) { [weak self] _ in
                guard let self = self, !self.isCompleted else { return }
                self.isCompleted = true
                self.manager.stopUpdatingLocation()
                let completion = self.onComplete
                self.onComplete = nil
                completion?(nil)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !isCompleted else { return }
        isCompleted = true
        timer?.invalidate()
        let completion = onComplete
        onComplete = nil
        completion?(locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard !isCompleted else { return }
        isCompleted = true
        timer?.invalidate()
        let completion = onComplete
        onComplete = nil
        completion?(nil)
    }
}
#endif
