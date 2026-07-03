# wifi_ftm

A Flutter plugin for high-precision WiFi Fine Timing Measurement (FTM) and Round-Trip-Time (RTT) ranging on Android.

This package supports both the legacy **IEEE 802.11mc** standard and the new **IEEE 802.11az (Next Generation Positioning)** introduced in Android 15.

[![pub package](https://img.shields.io/pub/v/wifi_ftm.svg)](https://pub.dev/packages/wifi_ftm)
[![license](https://img.shields.io/github/license/raylabz/wifi_ftm.svg)](https://github.com/raylabz/wifi_ftm/blob/main/LICENSE)

> [!WARNING]  
> **This package is only compatible with the Android platform**. Support for other platforms will be implemented once the respective native APIs and OS vendor support are available.

_Developed at [**UCLan Cyprus**](https://www.uclancyprus.ac.cy)._

---

## Features

*   **Capabilities Detection**: Check if the device hardware supports WiFi RTT and 802.11az.
*   **Access Point Scanning**: Discover nearby WiFi APs and identify RTT responders (MC/AZ).
*   **High-Precision Ranging**: Sub-meter accuracy ranging to one or more access points simultaneously.
*   **Auto-Negotiation**: Automatically uses 802.11az when both device and AP support it, falling back to 802.11mc.
*   **Detailed Metrics**: Get distance, RSSI, standard deviation, and success rate for every ranging session.

## Getting Started

### Android Requirements

*   **Minimum SDK**: 24 (Android 7.0)
*   **Compile SDK**: 35 (Android 15) for 802.11az support.
*   **Hardware**: The device must support the `PackageManager.FEATURE_WIFI_RTT` system feature.

### Permissions

Add the following permissions to your `AndroidManifest.xml`:

```xml
<!-- Required for WiFi Scanning and RTT -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />

<!-- Required for Android 13+ -->
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />
```

*Note: WiFi RTT also requires **Location Services** to be enabled on the device.*

---

## Usage

### Check Support and Capabilities

Before ranging, check if the device supports RTT and if permissions are granted.

```dart
final wifiFtm = WifiFtm();

// Quick support check
bool supported = await wifiFtm.isSupported();

// Detailed capabilities profile
FtmCapabilities capabilities = await wifiFtm.getCapabilities();

print("Android SDK: ${capabilities.androidVersion}");
print("Permissions Granted: ${capabilities.permissionsGranted}");

if (capabilities.isWifi80211azSupported) {
  print("Next Gen Positioning (802.11az) is supported!");
}
```

### Scan for Access Points

Scan to find responders that support the FTM protocol.

```dart
List<APScanResult> scanResults = await wifiFtm.scanAccessPoints();

for (var ap in scanResults) {
  if (ap.is80211mcResponder || ap.is80211azResponder) {
    print("Found RTT-capable AP: ${ap.ssid} (${ap.bssid})");
    print("Security: ${ap.capabilities.join(', ')}");
  }
}
```

### Perform Ranging

Perform ranging towards a list of BSSIDs. The plugin handles the native RTT request and returns detailed results.

```dart
List<String> targets = ["00:11:22:33:44:55"];
List<RangingResult> results = await wifiFtm.startRanging(targets);

for (var res in results) {
  if (res.status == RangingStatus.success) {
    print("Distance: ${res.distanceMeters}m (+/- ${res.distanceStdDevMm}mm)");
    print("RSSI: ${res.rssi} dBm");
    print("Protocol: ${res.is80211azResult ? '802.11az' : '802.11mc'}");
  } else {
    print("Ranging failed for ${res.macAddress}");
  }
}
```

---

## Data

### `FtmCapabilities`
Provides information about the device's RTT environment.
- `status`: Map of `Capability` enums (wifiRtt, wifi80211az).
- `permissionsGranted`: Current state of native permissions.
- `androidVersion`: System SDK level.
- `isWifiRttSupported` / `isWifi80211azSupported`: Convenience getters.

### `APScanResult`
Represents an Access Point discovered during a scan.
- `ssid` / `bssid`: Network identifiers.
- `level`: Signal strength (RSSI).
- `frequency`: Channel frequency in MHz.
- `is80211mcResponder` / `is80211azResponder`: Protocol support flags.
- `capabilities`: A parsed `List<String>` of security and network features (e.g., `WPA2-PSK`, `ESS`).

### `RangingResult`
The result of a ranging request to a specific AP.
- `distanceMm`: Distance in millimeters.
- `distanceMeters`: Distance in meters (convenience getter).
- `distanceStdDevMm`: Standard deviation of the measurement.
- `rssi`: Signal strength during ranging.
- `numSuccessfulMeasurements`: Number of successful bursts.
- `is80211azResult`: True if the measurement used the 802.11az protocol.

---

## Example & Permission handling

WiFi RTT operations are sensitive and require both system-level permissions and enabled services. For a complete implementation, check out the [example project](example/).

To manage permissions and services effectively in your app, we recommend using the following plugins:

*   [**permission_handler**](https://pub.dev/packages/permission_handler): To request `Permission.location` and `Permission.nearbyWifiDevices`.
*   [**geolocator**](https://pub.dev/packages/geolocator): To check if system-level Location Services are enabled.
*   [**app_settings**](https://pub.dev/packages/app_settings): To redirect users to system settings if permissions are denied.

## Contributing

Contributions and suggestions are welcome! Please feel free to submit an issue/pull request.

## License

This project is licensed under the Apache 2.0 License - see the LICENSE file for details.
