import 'src/models.dart';
import 'src/platform_interface.dart';

export 'src/models.dart';

class SentinelSDK {
  /// Initializes the Sentinel SDK with client API credentials.
  static Future<bool> initialize({
    required String apiKey,
    String environment = 'production',
  }) {
    return SentinelPlatform.instance.initialize(apiKey, environment);
  }

  /// Captures and validates user identity, device parameters, location, and gambling app screening.
  static Future<SentinelCaptureResult> capture({
    required SentinelUserDataInput userData,
    int timeoutMs = 5000,
  }) {
    return SentinelPlatform.instance.capture(userData, timeoutMs);
  }
}
