#import "SentinelReactNative.h"
#if __has_include("SentinelReactNative-Swift.h")
#import "SentinelReactNative-Swift.h"
#else
#import <SentinelReactNative/SentinelReactNative-Swift.h>
#endif

@implementation SentinelReactNative

RCT_EXPORT_MODULE(SentinelModule);

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

RCT_EXPORT_METHOD(initialize:(NSString *)apiKey
                  environment:(NSString *)environment
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [[SentinelReactNativeBridge shared] initializeWithApiKey:apiKey
                                                 environment:environment
                                                    resolver:^(id result) {
        resolve(result);
    } rejecter:^(NSString *code, NSString *message, NSError *error) {
        reject(code, message, error);
    }];
}

RCT_EXPORT_METHOD(capture:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [[SentinelReactNativeBridge shared] captureWithOptions:options
                                                  resolver:^(id result) {
        resolve(result);
    } rejecter:^(NSString *code, NSString *message, NSError *error) {
        reject(code, message, error);
    }];
}

@end
