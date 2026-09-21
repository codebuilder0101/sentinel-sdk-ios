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
        let rawMachineId = rawDeviceMachineIdentifier()
        let marketingModel = mapModelIdentifierToMarketingName(rawMachineId)
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
            model: marketingModel,
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
            model: "Generic iOS Device",
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

        let networkType = determineNetworkType()

        return SentinelTelephonyData(
            carrierName: carrierName,
            mobileCountryCode: mcc,
            mobileNetworkCode: mnc,
            isoCountryCode: isoCountry,
            networkType: networkType,
            isSimReady: isSimReady,
            simOperatorName: carrierName != "Unknown" ? carrierName : nil
        )
    }

    private func determineNetworkType() -> String {
        #if canImport(CoreTelephony)
        let networkInfo = CTTelephonyNetworkInfo()
        if let radioTechnology = networkInfo.serviceCurrentRadioAccessTechnology?.values.first {
            switch radioTechnology {
            case CTRadioAccessTechnologyNR, CTRadioAccessTechnologyNRNSA:
                return "CELLULAR_5G"
            case CTRadioAccessTechnologyLTE:
                return "CELLULAR_4G"
            case CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA, CTRadioAccessTechnologyHSUPA:
                return "CELLULAR_3G"
            default:
                break
            }
        }
        #endif
        return "WIFI"
    }

    public func checkJailbreakHeuristics() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/usr/bin/ssh",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/var/lib/cydia",
            "/usr/libexec/cydia-startup"
        ]

        for path in suspiciousPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // Test restricted write access in /private
        let testPath = "/private/sentinel_jb_test_\(UUID().uuidString).txt"
        do {
            try "jb_test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            // Write prohibited as expected in sandboxed environment
        }

        // Check for suspicious symbolic links on system directories
        let symlinkCheckPaths = ["/Applications", "/usr/share", "/Library/Ringtones"]
        for symlinkPath in symlinkCheckPaths {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: symlinkPath, isDirectory: &isDir) {
                if let dest = try? FileManager.default.destinationOfSymbolicLink(atPath: symlinkPath), !dest.isEmpty {
                    return true
                }
            }
        }

        // Check for injected dynamic libraries environment variables
        if let dyldInsert = getenv("DYLD_INSERT_LIBRARIES"), String(cString: dyldInsert).count > 0 {
            return true
        }

        return false
        #endif
    }

    private func checkSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private func rawDeviceMachineIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.isEmpty ? "iPhone" : identifier
    }

    public func mapModelIdentifierToMarketingName(_ identifier: String) -> String {
        let mapping: [String: String] = [
            // iPhone 15 Series
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            // iPhone 14 Series
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            // iPhone 13 Series
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,5": "iPhone 13",
            "iPhone14,4": "iPhone 13 mini",
            // iPhone 12 Series
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",
            "iPhone13,2": "iPhone 12",
            "iPhone13,1": "iPhone 12 mini",
            // iPhone 11 & SE
            "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,5": "iPhone 11 Pro Max",
            "iPhone12,8": "iPhone SE (2nd generation)",
            "iPhone14,6": "iPhone SE (3rd generation)",
            // Simulator
            "i386": "iOS Simulator (32-bit)",
            "x86_64": "iOS Simulator (x86_64)",
            "arm64": "iOS Simulator (arm64)"
        ]
        return mapping[identifier] ?? identifier
    }
}
