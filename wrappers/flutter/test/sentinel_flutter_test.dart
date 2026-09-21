import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_flutter/sentinel_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SentinelUserDataInput serializes to map properly', () {
    final input = SentinelUserDataInput(
      fullName: 'Carlos Eduardo',
      documentId: '12345678909',
      email: 'carlos@example.com',
      phoneNumber: '+5511999998888',
    );

    final map = input.toMap();
    expect(map['fullName'], 'Carlos Eduardo');
    expect(map['documentId'], '12345678909');
    expect(map['email'], 'carlos@example.com');
    expect(map['phoneNumber'], '+5511999998888');
  });

  test('SentinelCaptureResult parses raw JSON dictionary getters', () {
    final rawSample = {
      'metadata': {
        'sdk_version': '1.0.0',
        'platform': 'ios',
        'session_id': 'session-123',
      },
      'user_data': {
        'validation': {
          'is_valid': true,
          'validation_errors': <String>[],
        }
      },
      'device_data': {
        'device_identifier': 'device-123',
        'model': 'iPhone 15 Pro',
        'is_jailbroken_or_rooted': false,
        'telephony': {
          'carrier_name': 'Claro BR',
        }
      },
      'location_data': {
        'coordinates': {
          'latitude': -23.55052,
          'longitude': -46.633308,
          'accuracy_meters': 5.0,
        },
        'is_mock_location': false,
      },
      'installed_apps': {
        'risk_level': 'FLAGGED',
        'has_betting_apps': true,
        'total_targets_scanned': 25,
        'total_detected': 2,
      },
      'security': {
        'payload_hash': 'sha256_mock_hash',
        'signature': 'mock_signature',
        'nonce': 'nonce_123',
      }
    };

    final result = SentinelCaptureResult(rawSample);
    expect(result.sdkVersion, '1.0.0');
    expect(result.platform, 'ios');
    expect(result.isUserValid, true);
    expect(result.model, 'iPhone 15 Pro');
    expect(result.carrierName, 'Claro BR');
    expect(result.latitude, -23.55052);
    expect(result.riskLevel, 'FLAGGED');
    expect(result.hasBettingApps, true);
    expect(result.payloadHash, 'sha256_mock_hash');
  });
}
