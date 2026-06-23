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
    return const MaterialApp(
      home: HomePage(),
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
      message += "getCapabilities: $getCapabilities\n";
    });
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
      appBar: AppBar(title: const Text('WiFi FTM Example')),
      body: Center(child: Text(message, textAlign: TextAlign.center)),
    );
  }
}
