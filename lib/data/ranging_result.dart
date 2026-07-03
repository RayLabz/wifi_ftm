import 'package:wifi_ftm/data/ranging_status.dart';

/// Represents the result of a WiFi RTT ranging operation to a specific access point.
class RangingResult {
  /// The MAC address of the target access point.
  final String macAddress;

  /// The status of the ranging operation (success or failure).
  final RangingStatus status;

  /// The estimated distance to the access point in millimeters.
  final int distanceMm;

  /// The standard deviation of the measured distance in millimeters.
  final int distanceStdDevMm;

  /// The signal strength (RSSI) of the ranging measurements in dBm.
  final int rssi;

  /// The total number of measurement attempts made.
  final int numAttemptedMeasurements;

  /// The number of measurements that were successfully completed.
  final int numSuccessfulMeasurements;

  /// The timestamp in milliseconds when the ranging was performed.
  final int timestamp;

  /// Indicates if 802.11az (Next Gen Positioning) was used for this measurement.
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

  /// Creates a [RangingResult] from a map received via the platform channel.
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

  /// The estimated distance to the access point in meters.
  double get distanceMeters => distanceMm / 1000.0;

  @override
  String toString() {
    return 'RangingResult(mac: $macAddress, distance: ${distanceMeters}m, status: $status, az: $is80211azResult)';
  }
}
