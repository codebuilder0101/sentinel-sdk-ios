# Sentinel SDK: App Store & Google Play Compliance Guide

## 1. Google Play Store Policy Alignment

### Elimination of `QUERY_ALL_PACKAGES`
Google Play enforces strict justification requirements for the `QUERY_ALL_PACKAGES` permission, rejecting apps that do not require full device app visibility for their core user-facing functionality.

**Sentinel SDK Solution:**
- We do **not** declare or use `QUERY_ALL_PACKAGES`.
- We utilize the `<queries>` element in the SDK's library `AndroidManifest.xml`.
- When the host app compiles, Gradle automatically merges the SDK manifest with the host app manifest.
- This allows querying only the explicit, pre-defined betting package names (e.g. `com.bet365.app`, `gr.novibet`, etc.), fully satisfying Google Play Target API 30+ package visibility restrictions without triggering store review flags.

### Risk Assessment & Anti-Fraud Business Justification
In accordance with Google Play's Financial Services and Anti-Fraud guidelines, Sentinel SDK's app screening serves exclusively as a **Responsible Gaming & Financial Fraud Prevention Assessment** tool. It evaluates risk signals prior to credit or transaction authorization.

---

## 2. Apple App Store Compliance

### Sandbox Policy & `canOpenURL(_:)`
Apple sandboxes all third-party iOS applications and prohibits querying the filesystem or package manager for installed apps.

**Sentinel SDK Solution:**
- Detection strictly utilizes `UIApplication.shared.canOpenURL(_:)`.
- The target URL schemes (e.g., `bet365://`, `novibet://`) are declared in the host application's `Info.plist` under `LSApplicationQueriesSchemes`.
- **Known Limitation Handling**: For betting apps that do not register custom URL schemes, Sentinel SDK transparently classifies them as `unsupported_scheme_absent` in the response payload rather than causing silent failures.

### Apple Privacy Manifest (`PrivacyInfo.xcprivacy`)
Starting in iOS 17+, Apple requires frameworks to bundle a `PrivacyInfo.xcprivacy` file explaining:
1. **NSPrivacyAccessedAPITypes**:
   - `NSPrivacyAccessedAPICategorySystemBootTime`: Used for device uptime / replay attack prevention.
   - `NSPrivacyAccessedAPICategoryDiskSpace`: Used to detect simulator vs physical device environments.
2. **NSPrivacyCollectedDataTypes**:
   - `NSPrivacyCollectedDataTypePreciseLocation`: Fraud detection & compliance.
   - `NSPrivacyCollectedDataTypeDeviceID`: Fraud prevention.
   - `NSPrivacyCollectedDataTypeName`: Identity validation.
