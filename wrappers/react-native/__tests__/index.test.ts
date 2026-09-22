import { CaptureOptions, CapturePayload } from '../src/types';

describe('Sentinel React Native Wrapper Types', () => {
  it('should define valid CaptureOptions structure', () => {
    const options: CaptureOptions = {
      userData: {
        fullName: 'Carlos da Silva',
        documentId: '12345678909',
        email: 'carlos@example.com',
        phoneNumber: '+5511999998888',
      },
      timeoutMs: 5000,
    };

    expect(options.userData.fullName).toBe('Carlos da Silva');
    expect(options.timeoutMs).toBe(5000);
  });

  it('should validate complete CapturePayload shape against specification', () => {
    const payload: CapturePayload = {
      metadata: {
        sdk_version: '1.0.0',
        platform: 'android',
        os_version: '14.0',
        wrapper: 'react-native',
        session_id: 'session-123',
        request_id: 'req-123',
        timestamp: '2026-09-22T00:00:00.000Z',
        capture_duration_ms: 250,
      },
      user_data: {
        full_name: 'Carlos da Silva',
        document_id: '12345678909',
        email: 'carlos@example.com',
        phone_number: '+5511999998888',
        validation: {
          is_valid: true,
          name_format_valid: true,
          document_valid: true,
          phone_format_valid: true,
          validation_errors: [],
        },
      },
      device_data: {
        device_identifier: 'device-id-xyz',
        model: 'Pixel 8',
        manufacturer: 'Google',
        brand: 'google',
        locale: 'pt_BR',
        timezone: 'America/Sao_Paulo',
        screen_resolution: '1080x2400',
        battery_level: 0.9,
        battery_state: 'unplugged',
        is_jailbroken_or_rooted: false,
        is_emulator: false,
        telephony: {
          carrier_name: 'Claro BR',
          mobile_country_code: '724',
          mobile_network_code: '05',
          iso_country_code: 'br',
          network_type: 'CELLULAR_5G',
          is_sim_ready: true,
        },
      },
      location_data: {
        status: 'SUCCESS',
        permission_status: 'granted_fine',
        coordinates: {
          latitude: -23.55052,
          longitude: -46.633308,
          accuracy_meters: 4.2,
        },
        timestamp: '2026-09-22T00:00:00.000Z',
        is_mock_location: false,
      },
      installed_apps: {
        scan_strategy: 'targeted_manifest_queries',
        total_targets_scanned: 25,
        total_detected: 0,
        risk_level: 'CLEAN',
        has_betting_apps: false,
        detected_apps: [],
        unresolved_schemes_count: 0,
      },
      security: {
        payload_hash: 'sha256_hex_digest',
        signature: 'hmac_sha256_signature',
        nonce: 'nonce_123',
        tamper_detected: false,
      },
    };

    expect(payload.metadata.sdk_version).toBe('1.0.0');
    expect(payload.user_data.validation.is_valid).toBe(true);
    expect(payload.installed_apps.risk_level).toBe('CLEAN');
  });
});
