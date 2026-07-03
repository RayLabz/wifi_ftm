/// Represents a WiFi access point found during a scan.
class APScanResult {
  /// The network name (Service Set Identifier).
  final String ssid;

  /// The hardware address (Basic Service Set Identifier).
  final String bssid;

  /// The detected signal level in dBm, also known as the RSSI.
  final int level;

  /// The center frequency of the primary 20 MHz channel (in MHz).
  final int frequency;

  /// The timestamp in microseconds indicating when the result was last seen.
  final int timestamp;

  /// Indicates if the AP supports 802.11mc (Fine Timing Measurement).
  final bool is80211mcResponder;

  /// Indicates if the AP supports 802.11az (Next Gen Positioning).
  final bool is80211azResponder;

  /// The list of capabilities (e.g., [WPA2-PSK-CCMP], [ESS]).
  final List<String> capabilities;

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

  /// Creates an [APScanResult] from a map received via the platform channel.
  factory APScanResult.fromMap(Map<dynamic, dynamic> map) {
    final rawCaps = map['capabilities'] ?? '';
    return APScanResult(
      ssid: map['ssid'] ?? '',
      bssid: map['bssid'] ?? '',
      level: map['level'] ?? 0,
      frequency: map['frequency'] ?? 0,
      timestamp: map['timestamp'] ?? 0,
      is80211mcResponder: map['is80211mcResponder'] ?? false,
      is80211azResponder: map['is80211azResponder'] ?? false,
      capabilities: _parseCapabilities(rawCaps),
    );
  }

  /// Parses the raw Android capabilities string (e.g., "[WPA2-PSK-CCMP][ESS]") into a list.
  static List<String> _parseCapabilities(String raw) {
    if (raw.isEmpty) return [];
    final regex = RegExp(r'\[([^\]]+)\]');
    return regex.allMatches(raw).map((m) => m.group(1)!).toList();
  }

  @override
  String toString() {
    return 'APScanResult(ssid: $ssid, bssid: $bssid, level: $level, mc: $is80211mcResponder, az: $is80211azResponder)';
  }
}
