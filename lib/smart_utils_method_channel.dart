import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'smart_utils_platform_interface.dart';

/// An implementation of [SmartUtilsPlatform] that uses method channels.
class MethodChannelSmartUtils extends SmartUtilsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('smart_utils');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
