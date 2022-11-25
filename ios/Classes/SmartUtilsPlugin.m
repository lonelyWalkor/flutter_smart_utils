#import "SmartUtilsPlugin.h"
#if __has_include(<smart_utils/smart_utils-Swift.h>)
#import <smart_utils/smart_utils-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "smart_utils-Swift.h"
#endif

@implementation SmartUtilsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSmartUtilsPlugin registerWithRegistrar:registrar];
}
@end
