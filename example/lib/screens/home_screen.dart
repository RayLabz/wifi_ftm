import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_ftm/data/ap_scan_result.dart';
import 'package:wifi_ftm/wifi_ftm.dart';

import 'ap_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String message = 'Checking...';
  List<APScanResult> scanResults = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    // Observe lifecycle changes to re-check support when the app is resumed.
    WidgetsBinding.instance.addObserver(this);
    // Initial check for device support and permissions after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkSupport();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkSupport();
    }
  }

  /// Requests necessary permissions for Wi-Fi scanning and RTT ranging.
  /// On Android, this includes Location and Nearby Wi-Fi Devices (for Android 13+).
  Future<bool> requestPermissions() async {
    final permissions = <Permission>[Permission.location];
    if (Platform.isAndroid) {
      permissions.add(Permission.nearbyWifiDevices);
    }
    final result = await permissions.request();
    return result.values.every((status) => status.isGranted);
  }

  /// Checks if the device and system settings support Wi-Fi RTT.
  /// Validates permissions, location services, and hardware capability.
  Future<void> checkSupport() async {
    final permissionsGranted = await requestPermissions();

    if (!permissionsGranted) {
      setState(() {
        message = 'Required permissions denied';
      });
      return;
    }

    if (!mounted) return;
    final locationEnabled = await ensureLocationEnabled(context);

    if (!locationEnabled) {
      setState(() {
        message = 'Location services disabled';
      });
      return;
    }

    final wifiFtm = WifiFtm();
    final supported = await wifiFtm.isSupported();

    if (!supported) {
      setState(() {
        message = 'WiFi RTT not supported';
      });
      return;
    }

    final hasPermissions = await wifiFtm.hasPermissions();
    final capabilities = await wifiFtm.getCapabilities();

    setState(() {
      message = 'Wi-Fi RTT Supported\n';
      message += "Permissions: ${capabilities.permissionsGranted}\n";
      message += "SDK Version: ${capabilities.androidVersion}\n";
      message += "RTT Hardware: ${capabilities.isWifiRttSupported}\n";
      message += "802.11az Support: ${capabilities.isWifi80211azSupported}\n";
    });
  }

  /// Triggers a Wi-Fi scan to discover nearby Access Points.
  Future<void> startScan() async {
    setState(() {
      isScanning = true;
    });

    try {
      final wifiFtm = WifiFtm();
      final results = await wifiFtm.scanAccessPoints();
      setState(() {
        scanResults = results;
        isScanning = false;
      });
    } catch (e) {
      setState(() {
        isScanning = false;
        message = 'Scan failed: $e';
      });
    }
  }

  /// Verifies if Location Services are enabled, which is required for Wi-Fi scanning on Android.
  /// Prompts the user to open settings if disabled.
  Future<bool> ensureLocationEnabled(BuildContext context) async {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (enabled) {
      return true;
    }

    if (!context.mounted) return false;

    final shouldOpen =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Location Required'),
            content: const Text(
              'WiFi FTM ranging requires '
                  'Location Services to be enabled.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ) ??
            false;

    if (shouldOpen) {
      await Geolocator.openLocationSettings();
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi FTM Example'),
        actions: [
          if (isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: startScan,
              child: const Text('SCAN'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(message, textAlign: TextAlign.center),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                final ap = scanResults[index];
                final supportsRanging = ap.is80211mcResponder || ap.is80211azResponder;
                return ListTile(
                  title: Text(ap.ssid.isEmpty ? 'Hidden SSID' : ap.ssid),
                  subtitle: Text('${ap.bssid} | ${ap.frequency}MHz | ${ap.level}dBm'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ap.is80211mcResponder)
                        const Text('MC', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      if (ap.is80211mcResponder && ap.is80211azResponder)
                        const Text(' | '),
                      if (ap.is80211azResponder)
                        const Text('AZ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => APDetailsScreen(ap: ap),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}