class SentinelUserDataInput {
  final String fullName;
  final String? documentId;
  final String? email;
  final String? phoneNumber;

  SentinelUserDataInput({
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
  String get riskLevel => raw['installed_apps']?['risk_level'] ?? 'UNKNOWN';
  bool get hasBettingApps => raw['installed_apps']?['has_betting_apps'] ?? false;

  Map<String, dynamic> toJson() => raw;
}
