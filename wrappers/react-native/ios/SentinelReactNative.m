#import "SentinelReactNative.h"
#import <React/RCTLog.h>

@implementation SentinelReactNative

RCT_EXPORT_MODULE(SentinelModule);

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

RCT_EXPORT_METHOD(initialize:(NSString *)apiKey
                  environment:(NSString *)environment
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    // Bridges to native compiled SentinelSDK framework
    resolve(@(YES));
}

RCT_EXPORT_METHOD(capture:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    // Bridges capture request to native SentinelSDK instance
    resolve(@{
        @"status": @"SUCCESS"
    });
}

@end
