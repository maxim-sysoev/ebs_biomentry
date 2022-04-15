#import "EbsBiometryPlugin.h"
#if __has_include(<ebs_biometry/ebs_biometry-Swift.h>)
#import <ebs_biometry/ebs_biometry-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "ebs_biometry-Swift.h"
#endif

@implementation EbsBiometryPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftEbsBiometryPlugin registerWithRegistrar:registrar];
}
@end
