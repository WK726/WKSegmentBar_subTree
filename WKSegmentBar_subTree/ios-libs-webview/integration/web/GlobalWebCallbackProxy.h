//
//  GlobalWebCallbackProxy.h
//  ios-libs-webview
//
//  Created by cyan on 2017/10/20.
//  Copyright © 2017年 cyan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InterfaceProvider.h"

/**
     1、webview库实现native-js交互时,native to js的回调使用通知中心的方式实现，
     notificationCenter_webViewNeedCallBack_flag 是该通知中心的post name
     2、当js传回来的url.query包含callbackFlag时，该flag可以自定义：registCallbackTypeInfo,否则使用默认
 */
@interface GlobalWebCallbackProxy : NSObject

+ (GlobalWebCallbackProxy *)sharedWebCallbackProxy;

/**
     当交互url.query contain回调参数时，可以动态注册该回调参数的字符串标记
     key使用enum GZJSBridgeCallBackType
 */
- (void)registCallbackTypeInfo:(NSDictionary *)typeInfoDic;

- (NSString *)callbackTypeToName:(GZJSBridgeCallBackType)callbackType;
@end
