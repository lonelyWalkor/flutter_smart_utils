import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'smart_utils_method_channel.dart';

abstract class SmartUtilsPlatform extends PlatformInterface {
  /// Constructs a SmartUtilsPlatform.
  SmartUtilsPlatform() : super(token: _token);

  static final Object _token = Object();

  static SmartUtilsPlatform _instance = MethodChannelSmartUtils();

  /// The default instance of [SmartUtilsPlatform] to use.
  ///
  /// Defaults to [MethodChannelSmartUtils].
  static SmartUtilsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SmartUtilsPlatform] when
  /// they register themselves.
  static set instance(SmartUtilsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
