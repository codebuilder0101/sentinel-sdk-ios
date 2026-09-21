#import "SentinelFlutterPlugin.h"
#if __has_include(<sentinel_flutter/sentinel_flutter-Swift.h>)
#import <sentinel_flutter/sentinel_flutter-Swift.h>
#else
#import "sentinel_flutter-Swift.h"
#endif

@implementation SentinelFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SentinelFlutterPluginSwift registerWithRegistrar:registrar];
}

@end
