import 'package:flutter_test/flutter_test.dart';
import 'package:smart_utils/smart_utils.dart';
import 'package:smart_utils/smart_utils_platform_interface.dart';
import 'package:smart_utils/smart_utils_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSmartUtilsPlatform
    with MockPlatformInterfaceMixin
    implements SmartUtilsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SmartUtilsPlatform initialPlatform = SmartUtilsPlatform.instance;

  test('$MethodChannelSmartUtils is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSmartUtils>());
  });

  test('getPlatformVersion', () async {
    SmartUtils smartUtilsPlugin = SmartUtils();
    MockSmartUtilsPlatform fakePlatform = MockSmartUtilsPlatform();
    SmartUtilsPlatform.instance = fakePlatform;

    expect(await smartUtilsPlugin.getPlatformVersion(), '42');
  });
}
