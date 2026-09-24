# Sentinel SDK

[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-blue.svg)](https://github.com/codebuilder0101/sentinel-sdk-ios)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Kotlin](https://img.shields.io/badge/Kotlin-1.9+-purple.svg)](https://kotlinlang.org)
[![React Native](https://img.shields.io/badge/React%20Native-Supported-61dafb.svg)](https://reactnative.dev)
[![Flutter](https://img.shields.io/badge/Flutter-Supported-02569B.svg)](https://flutter.dev)
[![Store Compliance](https://img.shields.io/badge/App%20Store%20%26%20Play%20Store-Compliant-brightgreen.svg)](#privacy--store-compliance)

**Sentinel SDK** is a privacy-first, enterprise-grade mobile security SDK built for iOS and Android, accompanied by decoupled React Native and Flutter wrapper plugins. It securely captures, validates, and normalizes device telemetry, precise geolocation, user identity attributes, and targeted risk/gambling application screening to power real-time fraud prevention, onboarding authorization, and responsible-use compliance.

---

## 🚀 Key Features

- **Personal Data Validation**: Client-side format, checksum, and structure validation for names, document IDs, phone numbers, and emails.
- **Device & Telephony Telemetry**: Non-invasive device fingerprinting, carrier identification (MCC/MNC, operator name), network state, and jailbreak/root heuristics.
- **Precise Geolocation**: High-accuracy timestamped coordinates with horizontal/vertical accuracy filtering, speed, heading, and mock location spoofing detection.
- **Targeted App Detection (Gambling & Betting)**:
  - **Android**: Targeted `<queries>` package checking via `PackageManager` (100% compliant with Google Play Store policies, completely bypassing `QUERY_ALL_PACKAGES`).
  - **iOS**: Apple Sandbox-compliant `canOpenURL(_:)` probing against declared `LSApplicationQueriesSchemes`.
- **Payload Security & Tamper Resistance**: SHA-256 integrity hashing and cryptographic signature validation to safeguard payloads against transit tampering.
- **Binary Deliverables**: Pre-compiled `.xcframework` (iOS) and `.aar` (Android) to protect SDK proprietary source code from end clients.

---

## 📁 Repository Structure

```text
sentinel-sdk-ios/
├── specs/                        # Formal JSON Schemas & Target Databases
│   ├── payload.schema.json       # Draft JSON Response Schema v1
│   ├── sample_payload.json       # Verified Sample Response JSON
│   └── betting_apps_targets.json # Top 50 Targeted Betting App Identifiers
├── docs/                         # In-depth Guides & Compliance Mappings
│   ├── ARCHITECTURE.md           # Architecture & Data Flow
│   ├── COMPLIANCE.md             # Apple & Google Store Compliance Strategy
│   └── INTEGRATION.md            # Host App Integration Guide
├── ios/                          # Native iOS SDK & Demo App (Swift)
│   ├── Package.swift             # SPM Manifest
│   ├── Sources/SentinelSDK/      # SDK Core, Collectors, Models & Security
│   ├── Tests/SentinelSDKTests/   # Unit & Integration Tests
│   ├── SentinelDemo/             # iOS Sample Testing App (UIKit & SwiftUI)
│   │   ├── SentinelDemo.xcodeproj/
│   │   └── SentinelDemo/         # Views, Controllers, App Delegates & Info.plist
│   └── scripts/                  # XCFramework Build Automation
├── android/                      # Native Android SDK & Demo App (Kotlin)
│   ├── sentinel-core/            # Android Library Module
│   │   ├── src/main/AndroidManifest.xml # Target <queries> declaration
│   │   └── src/main/kotlin/com/sentinel/sdk/
│   ├── app/                      # Android Sample Testing App Module
│   └── build.gradle.kts
└── wrappers/                     # Cross-Platform Bridges
    ├── react-native/             # React Native Bridge (TS + Native Modules)
    └── flutter/                  # Flutter Plugin (Dart + MethodChannels)
```

---

## 🔒 Privacy & Store Compliance

| Platform | Policy / Requirement | Sentinel SDK Implementation |
| :--- | :--- | :--- |
| **Google Play** | `QUERY_ALL_PACKAGES` restrictions | **Zero broad queries**. Uses static `<queries>` in library `AndroidManifest.xml` targeting specific package IDs for fraud/risk prevention. |
| **Apple App Store** | Sandboxed Process & URL Schemes | Uses standard `canOpenURL(_:)` with declared `LSApplicationQueriesSchemes`. Transparently reports unmapped schemes. |
| **Apple App Store** | Privacy Manifest (`PrivacyInfo.xcprivacy`) | Bundles explicit `NSPrivacyCollectedDataTypes` and `NSPrivacyAccessedAPITypes` for device attributes and location. |
| **Location Services** | Permission Granularity | Transparently reports permission status (`authorized_when_in_use`, `denied`, etc.) and handles graceful degradation. |

---

## 🛠️ Quick Integration (React Native Preview)

```typescript
import { SentinelSDK, CaptureOptions } from '@sentinel/react-native';

// Initialize SDK
await SentinelSDK.initialize({
  apiKey: "YOUR_API_KEY",
  environment: "production"
});

// Capture data payload
const result = await SentinelSDK.capture({
  userData: {
    fullName: "João da Silva",
    documentId: "123.456.789-00",
    email: "joao.silva@example.com",
    phoneNumber: "+5511999998888"
  },
  timeoutMs: 10000
});

console.log("Sentinel Payload:", JSON.stringify(result, null, 2));
```

---

## 📦 Building Native Binaries

### iOS (`.xcframework`)
```bash
cd ios
chmod +x scripts/build_xcframework.sh
./scripts/build_xcframework.sh
```
Output: `ios/build/SentinelSDK.xcframework`

### Android (`.aar`)
```bash
cd android
./gradlew :sentinel-core:assembleRelease
```
Output: `android/sentinel-core/build/outputs/aar/sentinel-core-release.aar`

---

## 📄 License
Proprietary and Confidential. All rights reserved.
