import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wifi_ftm/wifi_ftm.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String message = 'Checking...';
  List<APScanResult> scanResults = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  Future<bool> requestPermissions() async {
    final permissions = <Permission>[Permission.location];
    if (Platform.isAndroid) {
      permissions.add(Permission.nearbyWifiDevices);
    }
    final result = await permissions.request();
    return result.values.every((status) => status.isGranted);
  }

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
    final getCapabilities = await wifiFtm.getCapabilities();

    setState(() {
      message = 'Wi-Fi RTT Supported\n';
      message += "hasPermissions: $hasPermissions\n";
      message += "Capabilities: $getCapabilities\n";
    });
  }

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
      body: Column(
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
                        builder: (context) => APDetailsPage(ap: ap),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class APDetailsPage extends StatefulWidget {
  final APScanResult ap;

  const APDetailsPage({super.key, required this.ap});

  @override
  State<APDetailsPage> createState() => _APDetailsPageState();
}

class _APDetailsPageState extends State<APDetailsPage> {
  RangingResult? rangingResult;
  bool isRanging = false;
  String? error;

  Future<void> performRanging() async {
    setState(() {
      isRanging = true;
      error = null;
      rangingResult = null;
    });

    try {
      final wifiFtm = WifiFtm();
      final results = await wifiFtm.startRanging([widget.ap.bssid]);
      if (results.isNotEmpty) {
        setState(() {
          rangingResult = results.first;
          isRanging = false;
        });
      } else {
        setState(() {
          error = 'No results returned';
          isRanging = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isRanging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportsRanging = widget.ap.is80211mcResponder || widget.ap.is80211azResponder;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ap.ssid.isEmpty ? 'AP Details' : widget.ap.ssid),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDetailRow('SSID', widget.ap.ssid.isEmpty ? 'Hidden' : widget.ap.ssid),
          _buildDetailRow('BSSID', widget.ap.bssid),
          _buildDetailRow('Signal Level', '${widget.ap.level} dBm'),
          _buildDetailRow('Frequency', '${widget.ap.frequency} MHz'),
          _buildDetailRow('Timestamp', widget.ap.timestamp.toString()),
          _buildDetailRow('802.11mc Support', widget.ap.is80211mcResponder ? 'Yes' : 'No'),
          _buildDetailRow('802.11az Support', widget.ap.is80211azResponder ? 'Yes' : 'No'),
          const Divider(),
          const Text('Capabilities:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.ap.capabilities),
          const SizedBox(height: 24),
          if (supportsRanging) ...[
            Center(
              child: ElevatedButton.icon(
                onPressed: isRanging ? null : performRanging,
                icon: isRanging
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.straighten),
                label: const Text('PERFORM RANGING'),
              ),
            ),
            if (rangingResult != null) ...[
              const SizedBox(height: 16),
              Card(
                color: rangingResult!.status == RangingStatus.success ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ranging Result (${rangingResult!.is80211azResult ? "802.11az" : "802.11mc"})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Status', rangingResult!.status.name.toUpperCase()),
                      if (rangingResult!.status == RangingStatus.success) ...[
                        _buildDetailRow('Distance', '${rangingResult!.distanceMeters.toStringAsFixed(3)} m'),
                        _buildDetailRow('Std Dev', '${(rangingResult!.distanceStdDevMm / 1000).toStringAsFixed(3)} m'),
                        _buildDetailRow('RSSI', '${rangingResult!.rssi} dBm'),
                        _buildDetailRow('Success Rate', '${rangingResult!.numSuccessfulMeasurements}/${rangingResult!.numAttemptedMeasurements}'),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ] else
            const Center(
              child: Text(
                'This Access Point does not support RTT/FTM ranging.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
