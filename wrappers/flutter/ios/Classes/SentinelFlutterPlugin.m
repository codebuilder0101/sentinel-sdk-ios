#import "SentinelFlutterPlugin.h"

@implementation SentinelFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"com.sentinel.sdk/channel"
            binaryMessenger:[registrar messenger]];
  SentinelFlutterPlugin* instance = [[SentinelFlutterPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"initialize" isEqualToString:call.method]) {
    result(@(YES));
  } else if ([@"capture" isEqualToString:call.method]) {
    // Returns serialized JSON payload from compiled SentinelSDK
    result(@"{\"status\":\"SUCCESS\"}");
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
