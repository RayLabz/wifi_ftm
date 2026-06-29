import 'package:flutter/material.dart';
import 'package:wifi_ftm/data/ap_scan_result.dart';
import 'package:wifi_ftm/data/ranging_result.dart';
import 'package:wifi_ftm/data/ranging_status.dart';
import 'package:wifi_ftm/wifi_ftm.dart';

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