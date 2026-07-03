import 'capability.dart';

/// Represents the full capability profile of the device.
class FtmCapabilities {
  /// A map of hardware-specific [Capability] supports.
  final Map<Capability, bool> status;

  /// Whether the necessary runtime permissions are currently granted.
  final bool permissionsGranted;

  /// The Android SDK version of the device.
  final int androidVersion;

  FtmCapabilities({
    required this.status,
    required this.permissionsGranted,
    required this.androidVersion,
  });

  /// Convenience getter for WiFi RTT support.
  bool get isWifiRttSupported => status[Capability.wifiRtt] ?? false;

  /// Convenience getter for 802.11az support.
  bool get isWifi80211azSupported => status[Capability.wifi80211az] ?? false;

  @override
  String toString() {
    return 'FtmCapabilities(rtt: $isWifiRttSupported, az: $isWifi80211azSupported, permissions: $permissionsGranted, sdk: $androidVersion)';
  }
}