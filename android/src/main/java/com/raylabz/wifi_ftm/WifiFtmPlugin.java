package com.raylabz.wifi_ftm;

import android.content.Context;
import android.content.pm.PackageManager;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import android.Manifest;
import androidx.core.content.ContextCompat;
import java.util.Map;
import java.util.HashMap;

public class WifiFtmPlugin
        implements FlutterPlugin,
        MethodChannel.MethodCallHandler {

    private MethodChannel channel;
    private Context context;

    @Override
    public void onAttachedToEngine(
            @NonNull FlutterPluginBinding binding) {

        context = binding.getApplicationContext();

        channel = new MethodChannel(
                binding.getBinaryMessenger(),
                "wifi_ftm");

        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(
            @NonNull FlutterPluginBinding binding) {

        channel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(
            @NonNull MethodCall call,
            @NonNull MethodChannel.Result result) {

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

            default:
                result.notImplemented();
        }
    }

    private boolean isSupported() {

        return context.getPackageManager()
                .hasSystemFeature(
                        PackageManager.FEATURE_WIFI_RTT);
    }

    private boolean hasPermissions() {

        boolean locationGranted =
                ContextCompat.checkSelfPermission(
                        context,
                        Manifest.permission.ACCESS_FINE_LOCATION)
                        == PackageManager.PERMISSION_GRANTED;

        if (android.os.Build.VERSION.SDK_INT >= 33) {

            boolean wifiGranted =
                    ContextCompat.checkSelfPermission(
                            context,
                            Manifest.permission.NEARBY_WIFI_DEVICES)
                            == PackageManager.PERMISSION_GRANTED;

            return locationGranted && wifiGranted;
        }

        return locationGranted;
    }

    private Map<String, Object> getCapabilities() {

        Map<String, Object> caps =
                new HashMap<>();

        caps.put(
                "wifiRtt",
                isSupported());

        caps.put(
                "permissionsGranted",
                hasPermissions());

        caps.put(
                "androidVersion",
                android.os.Build.VERSION.SDK_INT);

        return caps;
    }

}