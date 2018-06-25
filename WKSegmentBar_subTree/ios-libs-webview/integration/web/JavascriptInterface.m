//
//  JavascriptInterface.m
//  JavascriptInterface
//
//  Created by 7heaven on 16/7/14.
//  Copyright © 2016年 7heaven. All rights reserved.
//

#import "JavascriptInterface.h"
#import "objc/runtime.h"
#import "StringUtil.h"
#import "StringTool.h"
#import "GlobalWebCallbackProxy.h"
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

//#define ALLOW_INSECURE_INVOCATION
#define ALLOW_INJECTJS_AUTO
#define USE_IFRAME

static JavascriptInterface *sharedInterface;

@interface JavascriptInterface(){
    NSDictionary *pendingCallback;
}

@property (nonatomic, strong) NativeMethodExecHandler nativeMethodCallback;


///**
// * @brief 检查当前的URL是否为注入的JS方法的实际调用形式
// *
// * @param url 需要验证的url
// *
// * @return YES表示当前URL的格式符合JS方法对原生的实际调用
// */
//- (BOOL) checkUpcomingRequestURL:(NSURL *) url;

@end

@implementation JavascriptInterface

- (BOOL) handleInjectedJSMethod:(NSURL *) url originalRequest:(NSURLRequest* _Nullable)originalRequest callBack:(NativeMethodExecHandler _Nullable)handler{
    BOOL res = NO;
    if (self.interfaceProvider && [self.interfaceProvider respondsToSelector:@selector(handleInjectedJSMethod:originalRequest:callBack:)]) {
        res = [self.interfaceProvider handleInjectedJSMethod:url originalRequest:originalRequest  callBack:handler];
        if (!res) {
            res = [self execSelector:url.host query:url.query];
        }
    }
    return res;
}

- (BOOL) execSelector:(NSString *) host query:(NSString *) query{
    
    BOOL res = NO;
    SEL selector = [[self.interfaceProvider javascriptInterfaces][host] pointerValue];
#ifdef ALLOW_INSECURE_INVOCATION
    //允许js调用WebViewController的任意selector
    if(selector == nil) selector = NSSelectorFromString(host);
#endif
    if(selector && [self.interfaceProvider respondsToSelector:selector]){
        res = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMethodSignature *methodSignature = [((NSObject *) self.interfaceProvider) methodSignatureForSelector:selector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
            [invocation setTarget:self.interfaceProvider];
            [invocation setSelector:selector];
            
            /**
             回调产生的情形：
             1、js自带 callbackurl/method param,        传递回调string
             3、selector本身带返回值，                    立即执行回调
             */
            //-1 = 没有回调, 0 = 回调函数, 1 = 回调url
            int callbackType = -1;
            NSString *callbackMethod;
            if(query != nil){
                NSMutableArray *arguments = [[query componentsSeparatedByString:@"&"] mutableCopy];
                int count = (int) arguments.count;
                int i = 0;
                while(i < count){
                    NSString *content = arguments[i];
                    NSArray *keyvalue = [content componentsSeparatedByString:@"="];
                    if(keyvalue.count == 2){
                        NSString *key = keyvalue[0];
                        if([key isEqualToString:[[GlobalWebCallbackProxy sharedWebCallbackProxy] callbackTypeToName:(GZJSBridgeCallBackUrl)]]){
                            callbackType = 0;
                            callbackMethod = keyvalue[1];
                            [arguments removeObject:content];
                            count = (int) arguments.count;
                            pendingCallback = @{@"callbackType":@(GZJSBridgeCallBackUrl),@"callbackStr":keyvalue[1]};
                            continue;
                            
                        }else if([key isEqualToString:[[GlobalWebCallbackProxy sharedWebCallbackProxy] callbackTypeToName:GZJSBridgeCallBackFunc]]){
                            
                            callbackType = 1;
                            callbackMethod = keyvalue[1];
                            [arguments removeObject:content];
                            count = (int) arguments.count;
                            pendingCallback = @{@"callbackType":@(GZJSBridgeCallBackFunc),@"callbackStr":keyvalue[1]};
                            continue;
                        }else{
                            id arg = keyvalue[1];
                            NSUInteger argumentsNum = [methodSignature numberOfArguments];
                            if (i + 2 < argumentsNum) {
                                [invocation setArgument:&arg atIndex:i + 2];
                            }
                        }
                    }
                    i++;
                }
            }
            if (self.interfaceProvider && [self.interfaceProvider respondsToSelector:@selector(nativeMethodWillStartInvoke:callbackInfo:)]) {
                [self.interfaceProvider nativeMethodWillStartInvoke:selector callbackInfo:pendingCallback];
            }
            [invocation invoke];

            void *returnValue;
            char type[128];
            Method m = class_getInstanceMethod([self.interfaceProvider class], selector);
            method_getReturnType(m, type, sizeof(type));
            NSData *dataData = [NSData dataWithBytes:type length:sizeof(type)];
            NSString *returnS = [[NSString alloc] initWithData:dataData encoding:NSUTF8StringEncoding];
            
            if (!([returnS hasPrefix:@"v"] && type[1] == '\0')) {
                [invocation getReturnValue:&returnValue];
                [self.webView webviewEvaluatingJavascript:[NSString stringWithFormat:@"%@.retValue='%@';", self.interfaceName, returnValue] completeBlock:nil];
            }
            
            if (self.interfaceProvider && [self.interfaceProvider respondsToSelector:@selector(nativeMethodFinishInvoke:)]) {
                [self.interfaceProvider nativeMethodFinishInvoke:selector];
            }
        });
    }else{
        if (self.interfaceProvider && [self.interfaceProvider respondsToSelector:@selector(nativeMethodFailInvoke:)]) {
            [self.interfaceProvider nativeMethodFailInvoke:selector];
        }
    }
    return res;
}

- (void) injectJSMethod{
    
#ifdef ALLOW_INJECTJS_AUTO
    NSArray *injectStrings = self.injectingScripts;
    for (NSString *injectString in injectStrings) {
        [self.webView webviewEvaluatingJavascript:injectString completeBlock:nil];
    }
#endif
}

- (NSArray <NSString *>*)injectingScripts{
    if (self.interfaceProvider && [self.interfaceProvider respondsToSelector:@selector(javascriptInterfaces)]) {
        NSDictionary *list = [self.interfaceProvider javascriptInterfaces];
        
#ifdef USE_IFRAME
        NSMutableArray *injectStrings = [NSMutableArray array];
        //把所有的方法都拼到window下{interfaceName}对象内
        NSMutableString *injectString = [[NSMutableString alloc] init];
        [injectString appendString:[NSString stringWithFormat:@"window.%@ = {", @"nativeCommon"]];
        
        for(int i = 0; i < list.allKeys.count; i++){
            NSString *key = list.allKeys[i];
            SEL selector = [list[key] pointerValue];
            
            NSString *functionString = [self iframe_injectMethodStringForSelector:selector withJSName:key interfaceName:@"nativeCommon"];
            [injectString appendString:functionString];
            
            if(i != list.allKeys.count - 1){
                [injectString appendString:@","];
            }
        }
        [injectString appendString:@"};"];
        [injectStrings addObject:injectString];
        return [injectStrings copy];
#else
        NSMutableArray *array = [NSMutableArray array];
        NSString *script = [NSString stringWithFormat:@"var script = document.createElement('script');"
                            "script.type = 'text/javascript';"
                            "script.text = 'var nativeCommon = {};';"
                            "document.getElementsByTagName('head')[0].appendChild(script);"];
        [array addObject:script];
        for(int i = 0; i < list.allKeys.count; i++){
            NSString *key = list.allKeys[i];
            SEL selector = [list[key] pointerValue];
            NSString *script = [self document_injectMethodStringForSelector:selector withJSName:key interfaceName:@"nativeCommon"];
            [array addObject:script];
        }
        return array;
#endif
    }
    return nil;
}

- (NSString *) iframe_injectMethodStringForSelector:(SEL) selector withJSName:(NSString *) jsName interfaceName:(NSString *) interfaceName{
    
    NSString *string = NSStringFromSelector(selector);
    NSString *regExStr = @":";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regExStr options:NSRegularExpressionCaseInsensitive error:&error];
    NSInteger paramsCount = [regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    NSMutableString *resultString = [[NSMutableString alloc] init];
    [resultString appendString:[NSString stringWithFormat:@"%@: function (", jsName]];
    
    //实际的调用url
    NSMutableString *locationString = [[NSMutableString alloc] init];
    [locationString appendString:[NSString stringWithFormat:@"\"%@://%@", interfaceName, jsName]];
    if(paramsCount > 0) [locationString appendString:@"?"];
    [locationString appendString:@"\""];
    
    //对方法的参数进行拼接
    for(int i = 0; i < paramsCount; i++){
        if(i == paramsCount - 1){
            [resultString appendString:[NSString stringWithFormat:@"arg%d", i]];
            [locationString appendString:[NSString stringWithFormat:@" + \"arg%d=\" + arg%d", i, i]];
        }else{
            [resultString appendString:[NSString stringWithFormat:@"arg%d,", i]];
            [locationString appendString:[NSString stringWithFormat:@" + \"arg%d=\" + arg%d + \"&\"", i, i]];
        }
    }
    
    [resultString appendString:[NSString stringWithFormat:@"){"
                                "%@.retValue = null;"
                                "var iframe = document.createElement(\"IFRAME\");"
                                "iframe.setAttribute(\"src\", %@);"
                                "document.documentElement.appendChild(iframe);"
                                "iframe.parentNode.removeChild(iframe);"
                                "iframe = null;"
                                "var ret = %@.retValue;"
                                "if(ret){"
                                "return ret;"
                                "}}", interfaceName, locationString, interfaceName]];
    
    return resultString;
}


- (NSString *) document_injectMethodStringForSelector:(SEL)selector withJSName:(NSString *) jsName interfaceName:(NSString *) interfaceName{
    
//    Method m = class_getInstanceMethod([self class], selector);
//    int paramsCount = method_getNumberOfArguments(m) - 2;
    NSString *string = NSStringFromSelector(selector);
    NSString *regExStr = @":";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regExStr options:NSRegularExpressionCaseInsensitive error:&error];
    NSInteger paramsCount = [regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, [string length])];

    NSString *formFunction = @"(";
    NSString *domainString = [NSString stringWithFormat:@"\"%@://",interfaceName];
    NSString *formMessage =  [domainString stringByAppendingString:paramsCount == 0 ? jsName : [jsName stringByAppendingString:@"?"]];
    for(int i = 0; i < paramsCount; i++){
        
        NSString *argName = [NSString stringWithFormat:@"arg%d", i];
        formFunction = [formFunction stringByAppendingString:argName];
        formMessage = [formMessage stringByAppendingString:[NSString stringWithFormat:@"%@=\" + %@", argName, argName]];
        
        if(i < paramsCount - 1){
            formFunction = [formFunction stringByAppendingString:@","];
            formMessage = [formMessage stringByAppendingString:@" + \"&"];
        }
    }
    if(paramsCount == 0) formMessage = [formMessage stringByAppendingString:@"\""];
    formFunction = [formFunction stringByAppendingString:@")"];
    
    NSString *script = [NSString stringWithFormat:@"var script = document.createElement('script');"
                        "script.type = 'text/javascript';"
                        "script.text = 'nativeCommon.%@ = function%@ {"
                        "webkit.messageHandlers.nativeCommon.postMessage(%@);"
                        "var ret = nativeCommon.retValue;"
                        "if(ret){"
                        "return ret;"
                        "}"
                        "}';"
                        "document.getElementsByTagName('head')[0].appendChild(script);", jsName, formFunction, formMessage];
    return script;
}

////1、Iframe
//window.nativeCommon = {
//
//    removeNavBarButton: function (arg0){
//        nativeCommon.retValue = null;
//        var iframe = document.createElement("IFRAME");iframe.setAttribute("src", "nativeCommon://removeNavBarButton?" + "arg0=" + arg0);
//        document.documentElement.appendChild(iframe);iframe.parentNode.removeChild(iframe);iframe = null;
//        var ret = nativeCommon.retValue;if(ret){return ret;
//        }
//    }
//}

/////2、
/*
 nativeCommon.removeNavButton = function(arg0){
 document.location.href='gezi://removeNavButton?
 },
 .....
 */

////3、
//var script = document.createElement('script');
//    script.type = 'text/javascript';
//    script.text = 'nativeCommon.removeNavBarButton = function(arg0) {
//    webkit.messageHandlers.nativeCommon.postMessage("gezi://removeNavBarButton?arg0=" + arg0);}
//    document.getElementsByTagName('head')[0].appendChild(script);

//+ (BOOL) validateInterfaceName:(NSString *) name{
//    return name != nil && [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length != 0;
//}

//- (BOOL) checkUpcomingRequestURL:(NSURL *) url{
//
//    if(url != nil && [[self class] validateInterfaceName:self.interfaceName]){
//        NSString *urlString = url.absoluteString;
//        urlString = [urlString lowercaseString];
//        NSString *schemeString = [[NSString stringWithFormat:@"%@://", _interfaceName] lowercaseString];
//        NSString *compatibilityString = [[NSString stringWithFormat:@"%@://",_compatibilityName] lowercaseString];
//        return [urlString hasPrefix:schemeString] || [urlString hasPrefix:compatibilityString];
//    }
//
//    return NO;
//}


- (void)dealloc{
    
}

@end

