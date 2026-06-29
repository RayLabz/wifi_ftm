import 'package:wifi_ftm/data/ranging_status.dart';

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