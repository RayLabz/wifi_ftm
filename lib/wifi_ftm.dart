import 'package:flutter/services.dart';

import 'data/ap_scan_result.dart';
import 'data/capability.dart';
import 'data/ftm_capabilities.dart';
import 'data/ranging_result.dart';

export 'data/ap_scan_result.dart';
export 'data/capability.dart';
export 'data/ranging_result.dart';
export 'data/ranging_status.dart';

class WifiFtm {
  static const MethodChannel _channel = MethodChannel('wifi_ftm');

  /// Checks if the device hardware supports WiFi RTT.
  Future<bool> isSupported() async {
    return await _channel.invokeMethod<bool>('isSupported') ?? false;
  }

  /// Checks if the necessary permissions are granted on the native side.
  Future<bool> hasPermissions() async {
    return await _channel.invokeMethod<bool>('hasPermissions') ?? false;
  }

  /// Retrieves the device's RTT capabilities and environment status.
  Future<FtmCapabilities> getCapabilities() async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getCapabilities');
    if (result == null) {
      return FtmCapabilities(
        status: {},
        permissionsGranted: false,
        androidVersion: 0,
      );
    }

    return FtmCapabilities(
      status: {
        Capability.wifiRtt: result['wifiRtt'] ?? false,
        Capability.wifi80211az: result['is11azNtbSupported'] ?? false,
      },
      permissionsGranted: result['permissionsGranted'] ?? false,
      androidVersion: result['androidVersion'] ?? 0,
    );
  }

  /// Scans for nearby WiFi access points.
  Future<List<APScanResult>> scanAccessPoints() async {
    final List<dynamic>? results = await _channel.invokeMethod('scanAccessPoints');
    if (results == null) return [];
    return results.map((e) => APScanResult.fromMap(e as Map)).toList();
  }

  /// Initiates RTT ranging towards the specified BSSIDs.
  Future<List<RangingResult>> startRanging(List<String> bssids) async {
    final List<dynamic>? results = await _channel.invokeMethod('startRanging', {'bssids': bssids});
    if (results == null) return [];
    return results.map((e) => RangingResult.fromMap(e as Map)).toList();
  }
}
