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