import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wifi_ftm_platform_interface.dart';

/// An implementation of [WifiFtmPlatform] that uses method channels.
class MethodChannelWifiFtm extends WifiFtmPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('wifi_ftm');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
