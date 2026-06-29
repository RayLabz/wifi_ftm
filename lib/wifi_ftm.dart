import 'package:flutter/services.dart';

import 'data/ap_scan_result.dart';
import 'data/ranging_result.dart';


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

  Future<List<APScanResult>> scanAccessPoints() async {
    final List<dynamic>? results = await _channel.invokeMethod('scanAccessPoints');
    if (results == null) return [];
    return results.map((e) => APScanResult.fromMap(e as Map)).toList();
  }

  Future<List<RangingResult>> startRanging(List<String> bssids) async {
    final List<dynamic>? results = await _channel.invokeMethod('startRanging', {'bssids': bssids});
    if (results == null) return [];
    return results.map((e) => RangingResult.fromMap(e as Map)).toList();
  }
}
