
import 'smart_utils_platform_interface.dart';

class SmartUtils {
  Future<String?> getPlatformVersion() {
    return SmartUtilsPlatform.instance.getPlatformVersion();
  }
}
