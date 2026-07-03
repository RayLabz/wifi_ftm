/// Possible statuses of a WiFi RTT ranging operation.
enum RangingStatus {
  /// Ranging was successful.
  success,

  /// Ranging failed (e.g., target unreachable, internal error).
  failure,
}
