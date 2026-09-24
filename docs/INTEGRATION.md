# Sentinel SDK: Integration Guide

## 1. Prerequisites

### iOS
- iOS 14.0+ Deployment Target
- Swift 5.9+ / Xcode 15+
- Add permissions to your host `Info.plist`:
  ```xml
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Sentinel requires precise location to verify regional compliance.</string>
  <key>LSApplicationQueriesSchemes</key>
  <array>
      <string>bet365</string>
      <string>novibet</string>
      <string>sportingbet</string>
      <string>superbet</string>
      <string>kto</string>
      <string>betano</string>
      <string>betfair</string>
      <string>betsson</string>
      <string>rivalo</string>
      <string>onexbet</string>
      <string>pinnacle</string>
      <string>pokerstars</string>
  </array>
  ```

### Android
- Android SDK 24+ (Android 7.0+)
- Compile SDK 34+
- Add permissions to your host `AndroidManifest.xml` (location only; package queries merge automatically):
  ```xml
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
  ```

---

## 2. React Native Integration

### Installation
```bash
npm install @sentinel/react-native
# or
yarn add @sentinel/react-native
```

### iOS CocoaPods Setup
```bash
cd ios && pod install
```

### Code Example
```typescript
import React, { useState } from 'react';
import { Button, View, Text } from 'react-native';
import { SentinelSDK, CapturePayload } from '@sentinel/react-native';

export default function App() {
  const [result, setResult] = useState<CapturePayload | null>(null);

  const handleCapture = async () => {
    try {
      const payload = await SentinelSDK.capture({
        userData: {
          fullName: 'João da Silva',
          documentId: '123.456.789-00',
          email: 'joao.silva@example.com',
          phoneNumber: '+5511999998888'
        },
        timeoutMs: 10000
      });
      setResult(payload);
    } catch (error) {
      console.error('Sentinel Capture Error:', error);
    }
  };

  return (
    <View style={{ padding: 24, marginTop: 50 }}>
      <Button title="Run Sentinel Capture" onPress={handleCapture} />
      {result && <Text>{JSON.stringify(result, null, 2)}</Text>}
    </View>
  );
}
```

---

## 3. Flutter Integration

### Installation
Add to your `pubspec.yaml`:
```yaml
dependencies:
  sentinel_flutter:
    path: ../wrappers/flutter
```

### Code Example
```dart
import 'package:flutter/material.dart';
import 'package:sentinel_flutter/sentinel_flutter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Sentinel Flutter Demo')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final payload = await SentinelSDK.capture(
                userData: SentinelUserDataInput(
                  fullName: 'João da Silva',
                  documentId: '123.456.789-00',
                  email: 'joao.silva@example.com',
                  phoneNumber: '+5511999998888',
                ),
              );
              debugPrint('Captured: ${payload.toJson()}');
            },
            child: const Text('Capture Sentinel Data'),
          ),
        ),
      ),
    );
  }
}
```

---

## 4. Native Sample Apps for Verification & Testing

The repository provides fully functional native testing applications for both **iOS** and **Android** to verify telemetry collection, personal data validation, location services, and targeted betting app detection.

### 4.1 iOS Testing App (`ios/SentinelDemo`)
- **Location**: [`ios/SentinelDemo/`](file:///d:/Projects/sentinel-sdk-ios/ios/SentinelDemo/)
- **Xcode Project**: Open `ios/SentinelDemo/SentinelDemo.xcodeproj` in Xcode 15+.
- **Features**:
  - Valid and Invalid Identity Data Presets.
  - Native runtime location permission handling (`CLLocationManager`).
  - Target schemes screening (`canOpenURL` with declared `LSApplicationQueriesSchemes`).
  - Live Telemetry & Risk Summary badge metrics.
  - Formatted JSON inspector with one-click clipboard copying and iOS Share sheet.
  - Dual implementations: UIKit (`ViewController.swift`) and SwiftUI (`ContentView.swift`).

### 4.2 Android Testing App (`android/app`)
- **Location**: [`android/app/`](file:///d:/Projects/sentinel-sdk-ios/android/app/)
- **Run with Gradle**:
  ```bash
  cd android
  ./gradlew :app:installDebug
  ```
- **Features**:
  - Valid and Invalid Identity Data Presets.
  - Runtime permissions launcher for Fine & Coarse GPS.
  - Google Play-compliant `<queries>` risk screening without `QUERY_ALL_PACKAGES`.
  - Live Telemetry & Risk Summary badge metrics.
  - Formatted JSON inspector with clipboard copying.

