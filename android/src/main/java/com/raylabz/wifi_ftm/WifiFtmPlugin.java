package com.raylabz.wifi_ftm;

import android.content.Context;
import android.content.pm.PackageManager;
import android.net.wifi.WifiManager;
import android.net.wifi.ScanResult;
import android.net.wifi.rtt.RangingRequest;
import android.net.wifi.rtt.RangingResult;
import android.net.wifi.rtt.RangingResultCallback;
import android.net.wifi.rtt.WifiRttManager;
import android.os.Build;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import android.Manifest;

import androidx.core.content.ContextCompat;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

/**
 * WifiFtmPlugin provides WiFi Fine Timing Measurement (FTM) and Round-Trip-Time (RTT) ranging
 * capabilities for Flutter applications on Android.
 */
public class WifiFtmPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {

    private MethodChannel channel;
    private Context context;
    private WifiManager wifiManager;
    private WifiRttManager wifiRttManager;

    /** Stores results from the last scan to be used for ranging requests. */
    private final Map<String, ScanResult> lastScanResults = new HashMap<>();

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        // Initialize WiFi and RTT managers
        wifiManager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            wifiRttManager = (WifiRttManager) context.getSystemService(Context.WIFI_RTT_RANGING_SERVICE);
        }
        // Setup method channel
        channel = new MethodChannel(binding.getBinaryMessenger(), "wifi_ftm");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        // Handle incoming method calls from Flutter
        switch (call.method) {
            case "isSupported":
                result.success(isSupported());
                break;
            case "hasPermissions":
                result.success(hasPermissions());
                break;
            case "getCapabilities":
                result.success(getCapabilities());
                break;
            case "scanAccessPoints":
                scanAccessPoints(result);
                break;
            case "startRanging":
                startRanging(call, result);
                break;
            default:
                result.notImplemented();
        }
    }

    /**
     * Checks if the device supports WiFi RTT feature.
     * @return True if supported, false otherwise.
     */
    private boolean isSupported() {
        return context.getPackageManager().hasSystemFeature(PackageManager.FEATURE_WIFI_RTT);
    }

    /**
     * Checks if necessary permissions (Location and Nearby Devices) are granted.
     * @return True if all required permissions are granted.
     */
    private boolean hasPermissions() {
        boolean locationGranted = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;

        // Android 13+ (API 33) requires NEARBY_WIFI_DEVICES for WiFi operations
        if (Build.VERSION.SDK_INT >= 33) {
            boolean wifiGranted = ContextCompat.checkSelfPermission(context, Manifest.permission.NEARBY_WIFI_DEVICES) == PackageManager.PERMISSION_GRANTED;
            return locationGranted && wifiGranted;
        }

        return locationGranted;
    }

    /**
     * Retrieves device RTT capabilities, including 802.11az support.
     * @return A map containing RTT status and capability details.
     */
    private Map<String, Object> getCapabilities() {
        Map<String, Object> caps = new HashMap<>();
        caps.put("wifiRtt", isSupported());
        caps.put("permissionsGranted", hasPermissions());
        caps.put("androidVersion", Build.VERSION.SDK_INT);

        // Check for 802.11az (Next Gen Positioning) support on Android 15+
        if (Build.VERSION.SDK_INT >= 35 && wifiRttManager != null) {
            caps.put("is11azNtbSupported", wifiRttManager.getRttCharacteristics().getBoolean(android.net.wifi.rtt.WifiRttManager.CHARACTERISTICS_KEY_BOOLEAN_NTB_INITIATOR));
        }
        return caps;
    }

    /**
     * Scans for nearby WiFi access points and identifies RTT responders.
     * @param result Flutter result to return the list of scanned APs.
     */
    private void scanAccessPoints(MethodChannel.Result result) {
        if (!hasPermissions()) {
            result.error("PERMISSION_DENIED", "Required permissions not granted", null);
            return;
        }

        try {
            List<ScanResult> scanResults = wifiManager.getScanResults();
            List<Map<String, Object>> resultsList = new ArrayList<>();
            lastScanResults.clear();

            for (ScanResult scanResult : scanResults) {
                // Cache scan result for later ranging
                lastScanResults.put(scanResult.BSSID, scanResult);
                
                Map<String, Object> map = new HashMap<>();
                map.put("ssid", scanResult.SSID);
                map.put("bssid", scanResult.BSSID);
                map.put("level", scanResult.level);
                map.put("frequency", scanResult.frequency);
                map.put("timestamp", scanResult.timestamp);
                map.put("capabilities", scanResult.capabilities);

                // Identify 802.11mc (legacy RTT) support
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    map.put("is80211mcResponder", scanResult.is80211mcResponder());
                } else {
                    map.put("is80211mcResponder", false);
                }

                // Identify 802.11az (Next Gen Positioning) support
                if (Build.VERSION.SDK_INT >= 35) {
                    map.put("is80211azResponder", scanResult.is80211azNtbResponder());
                } else {
                    map.put("is80211azResponder", false);
                }

                resultsList.add(map);
            }
            result.success(resultsList);
        } catch (Exception e) {
            result.error("SCAN_ERROR", e.getMessage(), null);
        }
    }

    /**
     * Initiates RTT ranging towards the specified access points.
     * @param call Method call containing the BSSID list.
     * @param result Flutter result to return the ranging results.
     */
    private void startRanging(MethodCall call, MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P || wifiRttManager == null) {
            result.error("UNSUPPORTED", "WiFi RTT is not supported on this device/version", null);
            return;
        }

        List<String> bssids = call.argument("bssids");
        if (bssids == null || bssids.isEmpty()) {
            result.error("INVALID_ARGUMENT", "BSSID list is empty", null);
            return;
        }

        // Build the ranging request from cached scan results
        RangingRequest.Builder builder = new RangingRequest.Builder();
        int addedCount = 0;
        for (String bssid : bssids) {
            ScanResult sr = lastScanResults.get(bssid);
            if (sr != null) {
                builder.addAccessPoint(sr);
                addedCount++;
            }
        }

        if (addedCount == 0) {
            result.error("NO_MATCHING_AP", "None of the provided BSSIDs were found in the last scan", null);
            return;
        }

        try {
            wifiRttManager.startRanging(builder.build(), context.getMainExecutor(), new RangingResultCallback() {
                @Override
                public void onRangingFailure(int code) {
                    result.error("RANGING_FAILURE", "Ranging failed with code: " + code, null);
                }

                @Override
                public void onRangingResults(@NonNull List<RangingResult> results) {
                    List<Map<String, Object>> resultsList = new ArrayList<>();

                    for (RangingResult res : results) {
                        Map<String, Object> map = new HashMap<>();

                        map.put(
                                "macAddress",
                                res.getMacAddress() != null
                                        ? res.getMacAddress().toString()
                                        : ""
                        );

                        int status = res.getStatus();
                        map.put("status", status);

                        if (status == RangingResult.STATUS_SUCCESS) {
                            map.put("distanceMm", res.getDistanceMm());
                            map.put("distanceStdDevMm", res.getDistanceStdDevMm());
                            map.put("rssi", res.getRssi());
                            map.put("numAttemptedMeasurements",
                                    res.getNumAttemptedMeasurements());
                            map.put("numSuccessfulMeasurements",
                                    res.getNumSuccessfulMeasurements());
                            map.put("timestamp",
                                    res.getRangingTimestampMillis());

                            if (Build.VERSION.SDK_INT >= 35) {
                                map.put(
                                        "is80211azResult",
                                        res.is80211azNtbMeasurement()
                                );
                            } else {
                                map.put("is80211azResult", false);
                            }

                        } else {
                            // Measurement failed.
                            // Do NOT call getDistanceMm(), getRssi(), etc.
                            map.put("distanceMm", null);
                            map.put("distanceStdDevMm", null);
                            map.put("rssi", null);
                            map.put("numAttemptedMeasurements", null);
                            map.put("numSuccessfulMeasurements", null);
                            map.put("timestamp", null);
                            map.put("is80211azResult", false);
                        }

                        resultsList.add(map);
                    }

                    result.success(resultsList);
                }

            });
        } catch (Exception e) {
            result.error("RANGING_ERROR", e.getMessage(), null);
        }
    }

}