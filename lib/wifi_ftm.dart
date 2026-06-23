import 'package:flutter/services.dart';

class WifiFtm {
  static const MethodChannel _channel = MethodChannel('wifi_ftm');

  Future<bool> isSupported() async {
    return await _channel.invokeMethod<bool>('isSupported') ?? false;
  }

  Future<bool> hasPermissions() async {
    return await _channel.invokeMethod<bool>('hasPermissions') ?? false;
  }

  Future<Map<String, dynamic>> getCapabilities() async {
    final result = await _channel.invokeMethod('getCapabilities');

    return Map<String, dynamic>.from(result);
  }
}
