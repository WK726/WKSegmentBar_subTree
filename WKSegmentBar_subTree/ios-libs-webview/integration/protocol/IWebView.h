//
//  IWebView.h
//  JavascriptInterface
//
//  Created by 7heaven on 16/7/14.
//  Copyright © 2016年 7heaven. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InterfaceProvider.h"

NS_ASSUME_NONNULL_BEGIN

@protocol IWebView <NSObject>

/**
 * @brief 添加javascriptInterface
 *
 * @param target 提供js方法调用的对象
 *
 * @param name javascriptInterface名称
 */
- (void) addJavascriptInterface:(id<InterfaceProvider>) target forName:(NSString *) name;


- (void) webviewEvaluatingJavascript:(NSString *) script completeBlock:(nullable void(^)(__nullable id obj))complete;;
- (nullable NSString *) provideJS2NativeCallForMessage:(NSString *) message;

@optional

@end

NS_ASSUME_NONNULL_END
