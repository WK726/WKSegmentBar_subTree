//
//  JavascriptInterface.h
//  JavascriptInterface
//
//  Created by 7heaven on 16/7/14.
//  Copyright © 2016年 7heaven. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InterfaceProvider.h"
#import "IWebView.h"

@interface JavascriptInterface : NSObject

@property (weak, nonatomic) id webView;
@property (weak, nonatomic) id<InterfaceProvider> interfaceProvider;
@property (copy, nonatomic, readonly) NSArray <NSString *>* injectingScripts;

/**
 * @brief javascriptinterface名称，JS端调用的时候格式为{interfaceName}.{方法名}\n 例如:当前interfaceName为"nativeCommon", 方法为"callNative", 则JS的调用方式为nativeCommon.callNative();
 *
 */
@property (strong, nonatomic) NSString *interfaceName;

/**
 * @brief 注入JS方法，对应的原生方法和原生方法的JS端名称由InterfaceProvider提供
 *
 */
- (void) injectJSMethod;


/**
 * @brief 处理当前的URL并执行对应的原生方法
 *
 * @param url 传入的url
 *		  handler,执行原生方法后，对JS进行相应的回调
 *
 * @return YES表示当前url被作为JS对原生的调用处理，NO表示当前url格式不符合JS对原生调用或者未找到原生对应的方法
 */
- (BOOL) handleInjectedJSMethod:(NSURL *) url originalRequest:(NSURLRequest* _Nullable)originalRequest callBack:(NativeMethodExecHandler _Nullable)handler ;

@end
