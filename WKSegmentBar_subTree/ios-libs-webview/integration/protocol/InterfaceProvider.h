//
//  InterfaceProvider.h
//  JavascriptInterface
//
//  Created by 7heaven on 16/7/14.
//  Copyright © 2016年 7heaven. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  nativeMethod 执行完成后回调
 */
typedef NS_ENUM(NSInteger,GZJSBridgeCallBackType) {
    /**
     *  没有回调
     */
    GZJSBridgeNoCallBack = -1,
    /**
     *  执行 js 传过来的 callbackfunction
     */
    GZJSBridgeCallBackFunc,
    /**
     *   执行 js 传过来的 callbackurl
     */
    GZJSBridgeCallBackUrl,
    /**
     *   刷新整个页面
     */
    GZJSBridgeCallBackReloadPage
};

/**
 *  nativeMethod 执行完成后回调 JavaScript 或者 url
 *
 *  @param callbacktype  回调类型
 *  @param callbackStr  回调字符串(callbackFunc 暂时不支持有参数)
 */
typedef void(^NativeMethodExecHandler)(GZJSBridgeCallBackType callbacktype,NSString* callbackStr);


@protocol InterfaceProvider <NSObject>

/**
 * @brief 提供原生方法和JS调用的方法列表，格式为@{
 
 \@"{JS调用方法名}" : [NSValue valueWithPointer:\@selector({对应的原生方法})]
 
 }
 
 js方法的参数和原生方法的参数按顺序一一对应
 *
 * @return 返回包含对应JS方法名和原生Selector的字典
 */
- (NSDictionary<NSString *, NSValue *> *) javascriptInterfaces;


/**
 * @brief 分发requestURL
 * @return 表示是否可以处理该URL,yes表示已经处理该url
 */
- (BOOL) handleInjectedJSMethod:(NSURL *) url originalRequest:(NSURLRequest* _Nullable)originalRequest callBack:(NativeMethodExecHandler _Nullable)handler;


@optional


/**
 * @brief 提供native-method invoke的三个状态,callInfos表示jsmethod自带的一些回调字符串
 */
- (void)nativeMethodWillStartInvoke:(SEL)selector callbackInfo:(NSDictionary *)infos;
- (void)nativeMethodFinishInvoke:(SEL)selector;
- (void)nativeMethodFailInvoke:(SEL)selector;

@end

