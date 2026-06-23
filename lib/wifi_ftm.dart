import 'package:flutter/services.dart';

enum RangingStatus {
  success,
  failure,
}

class RangingResult {
  final String macAddress;
  final RangingStatus status;
  final int distanceMm;
  final int distanceStdDevMm;
  final int rssi;
  final int numAttemptedMeasurements;
  final int numSuccessfulMeasurements;
  final int timestamp;
  final bool is80211azResult;

  RangingResult({
    required this.macAddress,
    required this.status,
    required this.distanceMm,
    required this.distanceStdDevMm,
    required this.rssi,
    required this.numAttemptedMeasurements,
    required this.numSuccessfulMeasurements,
    required this.timestamp,
    required this.is80211azResult,
  });

  factory RangingResult.fromMap(Map<dynamic, dynamic> map) {
    return RangingResult(
      macAddress: map['macAddress'] ?? '',
      status: map['status'] == 0 ? RangingStatus.success : RangingStatus.failure,
      distanceMm: map['distanceMm'] ?? 0,
      distanceStdDevMm: map['distanceStdDevMm'] ?? 0,
      rssi: map['rssi'] ?? 0,
      numAttemptedMeasurements: map['numAttemptedMeasurements'] ?? 0,
      numSuccessfulMeasurements: map['numSuccessfulMeasurements'] ?? 0,
      timestamp: map['timestamp'] ?? 0,
      is80211azResult: map['is80211azResult'] ?? false,
    );
  }

  double get distanceMeters => distanceMm / 1000.0;

  @override
  String toString() {
    return 'RangingResult(mac: $macAddress, distance: ${distanceMeters}m, status: $status, az: $is80211azResult)';
  }
}

class APScanResult {
  final String ssid;
  final String bssid;
  final int level;
  final int frequency;
  final int timestamp;
  final bool is80211mcResponder;
  final bool is80211azResponder;
  final String capabilities;

  APScanResult({
    required this.ssid,
    required this.bssid,
    required this.level,
    required this.frequency,
    required this.timestamp,
    required this.is80211mcResponder,
    required this.is80211azResponder,
    required this.capabilities,
  });

  factory APScanResult.fromMap(Map<dynamic, dynamic> map) {
    return APScanResult(
      ssid: map['ssid'] ?? '',
      bssid: map['bssid'] ?? '',
      level: map['level'] ?? 0,
      frequency: map['frequency'] ?? 0,
      timestamp: map['timestamp'] ?? 0,
      is80211mcResponder: map['is80211mcResponder'] ?? false,
      is80211azResponder: map['is80211azResponder'] ?? false,
      capabilities: map['capabilities'] ?? '',
    );
  }

  @override
  String toString() {
    return 'APScanResult(ssid: $ssid, bssid: $bssid, level: $level, mc: $is80211mcResponder, az: $is80211azResponder)';
  }
}

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
