export interface UserDataInput {
  fullName: string;
  documentId?: string;
  email?: string;
  phoneNumber?: string;
}

export interface CaptureOptions {
  userData: UserDataInput;
  timeoutMs?: number;
}

export interface SentinelMetadata {
  sdk_version: string;
  platform: 'ios' | 'android';
  os_version: string;
  wrapper: string;
  session_id: string;
  request_id: string;
  timestamp: string;
  capture_duration_ms: number;
}

export interface SentinelUserData {
  full_name: string;
  document_id?: string | null;
  email?: string | null;
  phone_number?: string | null;
  validation: {
    is_valid: boolean;
    name_format_valid: boolean;
    document_valid: boolean;
    phone_format_valid: boolean;
    validation_errors: string[];
  };
}

export interface SentinelDeviceData {
  device_identifier: string;
  model: string;
  manufacturer: string;
  brand: string;
  locale: string;
  timezone: string;
  screen_resolution: string;
  battery_level: number;
  battery_state: 'charging' | 'unplugged' | 'full' | 'unknown';
  is_jailbroken_or_rooted: boolean;
  is_emulator: boolean;
  telephony: {
    carrier_name: string;
    mobile_country_code: string;
    mobile_network_code: string;
    iso_country_code: string;
    network_type: string;
    is_sim_ready: boolean;
    sim_operator_name?: string | null;
  };
}

export interface SentinelLocationData {
  status: 'SUCCESS' | 'PERMISSION_DENIED' | 'TIMEOUT' | 'UNAVAILABLE';
  permission_status: string;
  coordinates: {
    latitude: number;
    longitude: number;
    accuracy_meters: number;
    altitude_meters?: number | null;
    altitude_accuracy_meters?: number | null;
    heading_degrees?: number | null;
    speed_mps?: number | null;
  };
  timestamp: string;
  is_mock_location: boolean;
}

export interface SentinelDetectedApp {
  target_id: string;
  app_name: string;
  category: string;
  detection_identifier: string;
  detection_method: string;
  is_detected: boolean;
}

export interface SentinelInstalledApps {
  scan_strategy: string;
  total_targets_scanned: number;
  total_detected: number;
  risk_level: 'CLEAN' | 'FLAGGED' | 'UNKNOWN';
  has_betting_apps: boolean;
  detected_apps: SentinelDetectedApp[];
  unresolved_schemes_count: number;
}

export interface SentinelSecurityData {
  payload_hash: string;
  signature: string;
  nonce: string;
  tamper_detected: boolean;
}

export interface CapturePayload {
  $schema?: string;
  metadata: SentinelMetadata;
  user_data: SentinelUserData;
  device_data: SentinelDeviceData;
  location_data: SentinelLocationData;
  installed_apps: SentinelInstalledApps;
  security: SentinelSecurityData;
}
