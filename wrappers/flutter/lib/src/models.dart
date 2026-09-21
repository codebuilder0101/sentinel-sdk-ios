class SentinelUserDataInput {
  final String fullName;
  final String? documentId;
  final String? email;
  final String? phoneNumber;

  const SentinelUserDataInput({
    required this.fullName,
    this.documentId,
    this.email,
    this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'documentId': documentId,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }
}

class SentinelCaptureResult {
  final Map<String, dynamic> raw;

  SentinelCaptureResult(this.raw);

  String get sdkVersion => raw['metadata']?['sdk_version'] ?? '';
  String get platform => raw['metadata']?['platform'] ?? '';
  String get osVersion => raw['metadata']?['os_version'] ?? '';
  String get sessionId => raw['metadata']?['session_id'] ?? '';
  String get requestId => raw['metadata']?['request_id'] ?? '';
  String get timestamp => raw['metadata']?['timestamp'] ?? '';
  int get captureDurationMs => raw['metadata']?['capture_duration_ms'] ?? 0;

  bool get isUserValid => raw['user_data']?['validation']?['is_valid'] ?? false;
  List<String> get validationErrors =>
      List<String>.from(raw['user_data']?['validation']?['validation_errors'] ?? []);

  String get deviceIdentifier => raw['device_data']?['device_identifier'] ?? '';
  String get model => raw['device_data']?['model'] ?? '';
  String get carrierName => raw['device_data']?['telephony']?['carrier_name'] ?? '';
  bool get isJailbrokenOrRooted => raw['device_data']?['is_jailbroken_or_rooted'] ?? false;

  double get latitude => (raw['location_data']?['coordinates']?['latitude'] as num?)?.toDouble() ?? 0.0;
  double get longitude => (raw['location_data']?['coordinates']?['longitude'] as num?)?.toDouble() ?? 0.0;
  double get accuracyMeters => (raw['location_data']?['coordinates']?['accuracy_meters'] as num?)?.toDouble() ?? -1.0;
  bool get isMockLocation => raw['location_data']?['is_mock_location'] ?? false;

  String get riskLevel => raw['installed_apps']?['risk_level'] ?? 'UNKNOWN';
  bool get hasBettingApps => raw['installed_apps']?['has_betting_apps'] ?? false;
  int get totalTargetsScanned => raw['installed_apps']?['total_targets_scanned'] ?? 0;
  int get totalDetected => raw['installed_apps']?['total_detected'] ?? 0;

  String get payloadHash => raw['security']?['payload_hash'] ?? '';
  String get signature => raw['security']?['signature'] ?? '';
  String get nonce => raw['security']?['nonce'] ?? '';

  Map<String, dynamic> toJson() => raw;
}
