//
//  GlobalWebCallbackProxy.m
//  ios-libs-webview
//
//  Created by cyan on 2017/10/20.
//  Copyright © 2017年 cyan. All rights reserved.
//

#import "GlobalWebCallbackProxy.h"

@implementation GlobalWebCallbackProxy

static NSDictionary *callbackTypeToNameMap;

+ (GlobalWebCallbackProxy *)sharedWebCallbackProxy{
    static GlobalWebCallbackProxy *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[GlobalWebCallbackProxy alloc] init];
        callbackTypeToNameMap = @{
                                  @(GZJSBridgeCallBackFunc) : @"callbackMethod",
                                  @(GZJSBridgeCallBackUrl) : @"callbackUrl"
                                };
    });
    return proxy;
}

- (void)registCallbackTypeInfo:(NSDictionary *)typeInfoDic{
    
    //筛选合适的dicInfo
    NSMutableDictionary *infoDic = [NSMutableDictionary dictionary];
    if ([typeInfoDic.allKeys containsObject:@(GZJSBridgeCallBackUrl)]) {
        [infoDic setObject:@(GZJSBridgeCallBackUrl) forKey:infoDic[@(GZJSBridgeCallBackUrl)]];
    }
    if ([typeInfoDic.allKeys containsObject:@(GZJSBridgeCallBackFunc)]) {
        [infoDic setObject:@(GZJSBridgeCallBackFunc) forKey:infoDic[@(GZJSBridgeCallBackFunc)]];
    }
    callbackTypeToNameMap = [infoDic copy];
}

- (NSString *)callbackTypeToName:(GZJSBridgeCallBackType)callbackType{
    return callbackTypeToNameMap[@(callbackType)];
}

@end
