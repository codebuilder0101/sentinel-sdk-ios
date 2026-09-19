import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreTelephony)
import CoreTelephony
#endif
#if canImport(Network)
import Network
#endif

/// Collects hardware, OS, telephony, and integrity telemetry on iOS.
public final class DeviceDataCollector {

    public init() {}

    public func collect() -> SentinelDeviceData {
        #if os(iOS)
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        let deviceId = device.identifierForVendor?.uuidString ?? "00000000-0000-0000-0000-000000000000"
        let model = deviceModelIdentifier()
        let manufacturer = "Apple"
        let brand = "Apple"
        let locale = Locale.current.identifier
        let timezone = TimeZone.current.identifier

        let bounds = UIScreen.main.bounds
        let scale = UIScreen.main.scale
        let screenResolution = "\(Int(bounds.width * scale))x\(Int(bounds.height * scale))"

        let batteryLevel = max(0.0, device.batteryLevel)
        let batteryState: String
        switch device.batteryState {
        case .charging: batteryState = "charging"
        case .full: batteryState = "full"
        case .unplugged: batteryState = "unplugged"
        default: batteryState = "unknown"
        }

        let isJailbroken = checkJailbreakHeuristics()
        let isEmulator = checkSimulator()
        let telephony = collectTelephony()

        return SentinelDeviceData(
            deviceIdentifier: deviceId,
            model: model,
            manufacturer: manufacturer,
            brand: brand,
            locale: locale,
            timezone: timezone,
            screenResolution: screenResolution,
            batteryLevel: batteryLevel,
            batteryState: batteryState,
            isJailbrokenOrRooted: isJailbroken,
            isEmulator: isEmulator,
            telephony: telephony
        )
        #else
        return SentinelDeviceData(
            deviceIdentifier: UUID().uuidString,
            model: "Generic Device",
            manufacturer: "Apple",
            brand: "Apple",
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier,
            screenResolution: "0x0",
            batteryLevel: 1.0,
            batteryState: "unplugged",
            isJailbrokenOrRooted: false,
            isEmulator: true,
            telephony: SentinelTelephonyData(
                carrierName: "Unknown",
                mobileCountryCode: "000",
                mobileNetworkCode: "00",
                isoCountryCode: "xx",
                networkType: "WIFI",
                isSimReady: false
            )
        )
        #endif
    }

    private func collectTelephony() -> SentinelTelephonyData {
        var carrierName = "Unknown"
        var mcc = "000"
        var mnc = "00"
        var isoCountry = "xx"
        var isSimReady = false

        #if os(iOS) && canImport(CoreTelephony)
        let networkInfo = CTTelephonyNetworkInfo()
        if let providers = networkInfo.serviceSubscriberCellularProviders {
            for (_, carrier) in providers {
                if let name = carrier.carrierName, !name.isEmpty {
                    carrierName = name
                    mcc = carrier.mobileCountryCode ?? "000"
                    mnc = carrier.mobileNetworkCode ?? "00"
                    isoCountry = carrier.isoCountryCode ?? "xx"
                    isSimReady = true
                    break
                }
            }
        }
        #endif

        return SentinelTelephonyData(
            carrierName: carrierName,
            mobileCountryCode: mcc,
            mobileNetworkCode: mnc,
            isoCountryCode: isoCountry,
            networkType: "CELLULAR_5G",
            isSimReady: isSimReady,
            simOperatorName: carrierName != "Unknown" ? carrierName : nil
        )
    }

    private func checkJailbreakHeuristics() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        let paths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        // Check write permission in private directory
        let testPath = "/private/sentinel_jb_test.txt"
        do {
            try "jb_test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
        #endif
    }

    private func checkSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private func deviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.isEmpty ? "iPhone" : identifier
    }
}
