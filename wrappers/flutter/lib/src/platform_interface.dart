import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'models.dart';
import 'dart:convert';

abstract class SentinelPlatform extends PlatformInterface {
  SentinelPlatform() : super(token: _token);

  static final Object _token = Object();
  static SentinelPlatform _instance = MethodChannelSentinel();

  static SentinelPlatform get instance => _instance;

  static set instance(SentinelPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> initialize(String apiKey, String environment);
  Future<SentinelCaptureResult> capture(SentinelUserDataInput userData, int timeoutMs);
}

class MethodChannelSentinel extends SentinelPlatform {
  final MethodChannel _channel = const MethodChannel('com.sentinel.sdk/channel');

  @override
  Future<bool> initialize(String apiKey, String environment) async {
    final result = await _channel.invokeMethod<bool>('initialize', {
      'apiKey': apiKey,
      'environment': environment,
    });
    return result ?? false;
  }

  @override
  Future<SentinelCaptureResult> capture(SentinelUserDataInput userData, int timeoutMs) async {
    final result = await _channel.invokeMethod<String>('capture', {
      'userData': userData.toMap(),
      'timeoutMs': timeoutMs,
      'wrapper': 'flutter',
    });

    if (result == null) {
      throw Exception('Sentinel SDK capture returned empty response');
    }

    final decoded = json.decode(result) as Map<String, dynamic>;
    return SentinelCaptureResult(decoded);
  }
}
