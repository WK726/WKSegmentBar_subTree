//
//  GZBaseWebViewController.h
//  gezilicai
//
//  Created by gslicai on 16/6/29.
//  Copyright © 2016年 yuexue. All rights reserved.
//

#import "GZWebManagerDelegate.h"
#import "InterfaceProvider.h"
#import "GZWebViewDelegate.h"
#import "GZWebviewRefreshDelegate.h"

NS_ASSUME_NONNULL_BEGIN

typedef  NS_ENUM(int, WebviewType){
    WK_WebView,
    UI_WebView
};

@interface GZBaseWebViewController : UIViewController<GZWebviewRefreshDelegate>

@property (nonatomic, assign) WebviewType webviewType;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, copy) NSString *interfaceName;
@property (nonatomic, copy) NSString *compatibility_interfaceName;  //attribute use in js for native-inter-js,不区分大小写
@property (nonatomic, assign) BOOL disableRefresh;
@property (nonatomic, assign) BOOL disableProgress;

@property (nonatomic,weak, nullable) id<InterfaceProvider> interfaceProvider;
@property (nonatomic,weak, nullable) id<GZWebManagerDelegate> delegate;
@property (nonatomic,weak, nullable) id<GZWebViewDelegate> webViewAdapter;


+ (instancetype) newInstanceWithUrl:(NSString *)url andDelegate:(nullable NSObject<GZWebManagerDelegate> *)__weak delegate;

- (BOOL)canGoBack;
- (void)goBack;
- (BOOL)canGoForward;
- (void)goForward;
- (void)reloadURL;
- (void)stopLoading;
//- (void)forwardPage;
//- (void)backForwardPage;  //holding method

- (void)openURL:(NSURL*)url;
- (void)loadHTMLString:(NSString *)string baseURL:(nullable NSURL *)baseURL;
- (void)evaluateJavaScript:(NSString*)javaScriptString completeBlock:(nullable void(^)(__nullable id obj))complete;
@end

NS_ASSUME_NONNULL_END
