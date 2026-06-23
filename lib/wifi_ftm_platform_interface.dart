import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'wifi_ftm_method_channel.dart';

abstract class WifiFtmPlatform extends PlatformInterface {
  /// Constructs a WifiFtmPlatform.
  WifiFtmPlatform() : super(token: _token);

  static final Object _token = Object();

  static WifiFtmPlatform _instance = MethodChannelWifiFtm();

  /// The default instance of [WifiFtmPlatform] to use.
  ///
  /// Defaults to [MethodChannelWifiFtm].
  static WifiFtmPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WifiFtmPlatform] when
  /// they register themselves.
  static set instance(WifiFtmPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
