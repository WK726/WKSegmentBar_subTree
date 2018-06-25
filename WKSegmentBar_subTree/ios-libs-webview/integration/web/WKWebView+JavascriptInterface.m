
//
//  WKWebView+JavascriptInterface.m
//  gezilicai
//
//  Created by cuiyan on 16/11/9.
//  Copyright © 2016年 yuexue. All rights reserved.
//

#import "WKWebView+JavascriptInterface.h"
#import "SweezeTool.h"
#import "JavascriptInterface.h"

#define JAVASCRIPTINTERFACE "_javascriptInterface"
#define DELEGATE "_delegate"
#define NAVIGATIONDELEGATE "_navigationDelegate"
#define WKSCRIPTMESSAGEHANDLER "_wKScriptMessageHandler"

@implementation WKUserContentController(JavascriptInterface)

+ (void)load{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        [SweezeTool swizzleSelector:@selector(wk_addScriptMessageHandler:name:) withTargetSelector:@selector(addScriptMessageHandler:name:) class:[self class]];
        [SweezeTool swizzleSelector:@selector(wk_init) withTargetSelector:@selector(init) class:[self class]];
    });
}

- (instancetype)wk_init{
    
    if ([self wk_init]) {
        
        [self addScriptMessageHandler:nil name:nil];
    }
    return self;
}

- (void)setJSInterface:(JavascriptInterface *)interface{
    
    objc_setAssociatedObject(self, JAVASCRIPTINTERFACE, interface, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (JavascriptInterface *)getJSInterface{
    
    return objc_getAssociatedObject(self, JAVASCRIPTINTERFACE);
}

- (void)wk_addScriptMessageHandler:(id<WKScriptMessageHandler>)scriptMessageHandler name:(NSString *)name{
	
    if (scriptMessageHandler && scriptMessageHandler != self){
        [self setWKScriptMessageHandler:scriptMessageHandler];
    }
    if (name != nil) {
        [self wk_addScriptMessageHandler:self name:name];
    }
}

- (void)setWKScriptMessageHandler:(id<WKScriptMessageHandler>)handler{
    
    objc_setAssociatedObject(self, WKSCRIPTMESSAGEHANDLER, handler, OBJC_ASSOCIATION_ASSIGN);
}

- (id<WKScriptMessageHandler>)getWKScriptMessageHandler{
    
    return objc_getAssociatedObject(self, WKSCRIPTMESSAGEHANDLER);
}

#pragma mark -- script message handler delegate
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    
    JavascriptInterface *interface = [self getJSInterface];
    id<WKScriptMessageHandler> msgHandler = [self getWKScriptMessageHandler];
    NSString* urlStr = [NSString stringWithString:message.body];
    NSURL* url = [NSURL URLWithString:[urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]];
    
    BOOL res = NO;
    if (interface != nil) {
        res = [interface handleInjectedJSMethod:url originalRequest:nil callBack:^(GZJSBridgeCallBackType callbacktype, NSString *callbackStr) {
            
            if (callbacktype == GZJSBridgeNoCallBack) {
            }
            if (callbacktype == GZJSBridgeCallBackFunc) {
                [message.webView webviewEvaluatingJavascript:callbackStr completeBlock:nil];
            }
            if (callbacktype == GZJSBridgeCallBackUrl) {
                [message.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:callbackStr]]];
            }
            if (callbacktype == GZJSBridgeCallBackReloadPage) {
                [message.webView reload];
            }
        }];
    }
    if ( !res && [msgHandler respondsToSelector:@selector(userContentController:didReceiveScriptMessage:)]){
        [msgHandler userContentController:userContentController didReceiveScriptMessage:message];
    }
}

@end

@interface WKWebView ()

@end

@implementation WKWebView (JavascriptInterface)

+ (void)load{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        //方法交换
        [SweezeTool swizzleSelector:@selector(wk_initWithFrame:configuration:) withTargetSelector:@selector(initWithFrame:configuration:) class:[self class]];
        [SweezeTool swizzleSelector:@selector(wk_initWithCoder:) withTargetSelector:@selector(initWithCoder:) class:[self class]];
        [SweezeTool swizzleSelector:@selector(wk_setUIDelegate:) withTargetSelector:@selector(setUIDelegate:) class:[self class]];
        [SweezeTool swizzleSelector:@selector(wk_setNavigationDelegate:) withTargetSelector:@selector(setNavigationDelegate:) class:[self class]];
    });
}

- (void)initJSInterface{
    
    JavascriptInterface *javaInterface = [[JavascriptInterface alloc]init];
    [self setJavascriptInterface:javaInterface];
}

- (void)setJavascriptInterface:(JavascriptInterface *)inteface{
    
    objc_setAssociatedObject(self, JAVASCRIPTINTERFACE, inteface, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (JavascriptInterface *)getJavascriptInterface{
    
    return objc_getAssociatedObject(self, JAVASCRIPTINTERFACE);
}

- (instancetype)wk_initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration{
    
    if ([self wk_initWithFrame:frame configuration:configuration]) {
        
        [self setUIDelegate:nil];
        [self setNavigationDelegate:nil];
        [self initJSInterface];
    }
    
    return self;
}

- (instancetype)wk_initWithCoder:(NSCoder *)coder{

    if ([self wk_initWithCoder:coder]) {
     
        [self setUIDelegate:nil];
        [self setNavigationDelegate:nil];
        [self initJSInterface];
    }
    
    return self;
}

- (void)wk_setUIDelegate:(id<WKUIDelegate>)UIDelegate{
    
    if (UIDelegate == nil) {
        [self wk_setUIDelegate:self];
    }else if(UIDelegate != self){
        
        objc_setAssociatedObject(self, DELEGATE, UIDelegate, OBJC_ASSOCIATION_ASSIGN);
    }
}

- (id<WKUIDelegate>)wk_getUIDelegate{
    
    return objc_getAssociatedObject(self, DELEGATE);
}

- (void)wk_setNavigationDelegate:(id<WKNavigationDelegate>)UIDelegate{
    
    if (UIDelegate == nil) {
        [self wk_setNavigationDelegate:self];
    }else if(UIDelegate != self){
        objc_setAssociatedObject(self, NAVIGATIONDELEGATE, UIDelegate, OBJC_ASSOCIATION_ASSIGN);
    }
}

- (id<WKNavigationDelegate>)wk_getNavigationDelegate{
    
    return objc_getAssociatedObject(self, NAVIGATIONDELEGATE);
}

//#pragma mark -- Navigation UIdelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    
    id<WKNavigationDelegate> wkNavigationDelegate = [self wk_getNavigationDelegate];
    JavascriptInterface *inteface = [self getJavascriptInterface];
    NSURL *url = navigationAction.request.URL;
    
    BOOL res = NO;
    if (inteface != nil) {
        __weak typeof (self) weakSelf = self;
        res = [inteface handleInjectedJSMethod:url originalRequest:navigationAction.request callBack:^(GZJSBridgeCallBackType callbacktype, NSString *callbackStr) {
            
            if (callbacktype == GZJSBridgeNoCallBack) {
            }
            if (callbacktype == GZJSBridgeCallBackFunc) {
                [weakSelf webviewEvaluatingJavascript:callbackStr completeBlock:nil];
            }
            if (callbacktype == GZJSBridgeCallBackUrl) {
                [weakSelf loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:callbackStr]]];
            }
            if (callbacktype == GZJSBridgeCallBackReloadPage) {
                [weakSelf reload];
            }
        }];
    }
    if ( !res && wkNavigationDelegate != nil && [wkNavigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [wkNavigationDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    }else{
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    
    id<WKNavigationDelegate> wkNavigationDelegate = [self wk_getNavigationDelegate];
    if ([wkNavigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationResponse:decisionHandler:)]) {
        [wkNavigationDelegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    }else{
        decisionHandler(WKNavigationResponsePolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    id<WKNavigationDelegate> wkNavigationDelegate = [self wk_getNavigationDelegate];
    if ([wkNavigationDelegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [wkNavigationDelegate webView:webView didStartProvisionalNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
    id<WKNavigationDelegate> wkNavigationDelegate = [self wk_getNavigationDelegate];
    if ([wkNavigationDelegate respondsToSelector:@selector(webView:didReceiveServerRedirectForProvisionalNavigation:)]) {
        [wkNavigationDelegate webView:webView didReceiveServerRedirectForProvisionalNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    id<WKNavigationDelegate> wkNavigationDelegate = [self wk_getNavigationDelegate];
    if ([wkNavigationDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
        [wkNavigationDelegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    id<WKNavigationDelegate> wkNavigationDelegate = [self wk_getNavigationDelegate];
    if ([wkNavigationDelegate respondsToSelector:@selector(webView:didCommitNavigation:)]) {
        [wkNavigationDelegate webView:webView didCommitNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    
//    JavascriptInterface *inteface = [self getJavascriptInterface];
//    [inteface injectJSMethod];
    
    id<WKNavigationDelegate> wkNavigationDelegate = [self wk_getNavigationDelegate];
    if ([wkNavigationDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [wkNavigationDelegate webView:webView didFinishNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    id<WKNavigationDelegate> wkNavigationDelegate = [self wk_getNavigationDelegate];
    if ([wkNavigationDelegate respondsToSelector:@selector(webView:didFailNavigation:withError:)]) {
        [wkNavigationDelegate webView:webView didFailNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    id<WKNavigationDelegate> wkNavigationDelegate = [self wk_getNavigationDelegate];
    if ([wkNavigationDelegate respondsToSelector:@selector(webView:didReceiveAuthenticationChallenge:completionHandler:)]) {
        [wkNavigationDelegate webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    }else{
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling,nil);
    }
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    id<WKNavigationDelegate> wkNavigationDelegate = [self wk_getNavigationDelegate];
    if ([wkNavigationDelegate respondsToSelector:@selector(webViewWebContentProcessDidTerminate:)]) {
        [wkNavigationDelegate webViewWebContentProcessDidTerminate:webView];
    }
}

//----------- UI delegate
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    id<WKUIDelegate> WkUIDelegate = [self wk_getUIDelegate];
    if ([WkUIDelegate respondsToSelector:@selector(webView:createWebViewWithConfiguration:forNavigationAction:windowFeatures:)]) {
        return [WkUIDelegate webView:webView createWebViewWithConfiguration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
    }
    return nil;
}

- (void)webViewDidClose:(WKWebView *)webView{
    id<WKUIDelegate> WkUIDelegate = [self wk_getUIDelegate];
    if ([WkUIDelegate respondsToSelector:@selector(webViewDidClose:)]) {
        [WkUIDelegate webViewDidClose:webView];
    }
}

- (void) webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
        completionHandler();
    id<WKUIDelegate> WkUIDelegate = [self wk_getUIDelegate];
    if ([WkUIDelegate respondsToSelector:@selector(webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        [WkUIDelegate webView:webView runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }
}

- (void) webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    id<WKUIDelegate> WkUIDelegate = [self wk_getUIDelegate];
    if ([WkUIDelegate respondsToSelector:@selector(webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        [WkUIDelegate webView:webView runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }
}

- (void) webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    id<WKUIDelegate> WkUIDelegate = [self wk_getUIDelegate];
    if ([WkUIDelegate respondsToSelector:@selector(webView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:)]) {
        [WkUIDelegate webView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:completionHandler];
    }
}

- (BOOL)webView:(WKWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo{
    id<WKUIDelegate> WkUIDelegate = [self wk_getUIDelegate];
    if ([WkUIDelegate respondsToSelector:@selector(webView:shouldPreviewElement:)]) {
        return [WkUIDelegate webView:webView shouldPreviewElement:elementInfo];
    }
    return NO;
}

- (nullable UIViewController *)webView:(WKWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo defaultActions:(NSArray<id <WKPreviewActionItem>> *)previewActions{
    id<WKUIDelegate> WkUIDelegate = [self wk_getUIDelegate];
    if ([WkUIDelegate respondsToSelector:@selector(webView:previewingViewControllerForElement:defaultActions:)]) {
        return [WkUIDelegate webView:webView previewingViewControllerForElement:elementInfo defaultActions:previewActions];
    }
    return nil;
}

- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController{
    id<WKUIDelegate> WkUIDelegate = [self wk_getUIDelegate];
    if ([WkUIDelegate respondsToSelector:@selector(webView:commitPreviewingViewController:)]) {
        [WkUIDelegate webView:webView commitPreviewingViewController:previewingViewController];
    }
}

#pragma mark-- IWebview Delegate
- (void)addJavascriptInterface:(id<InterfaceProvider>)target forName:(NSString *)name{
    JavascriptInterface *inferface = [self getJavascriptInterface];
    inferface.webView = self;
    inferface.interfaceProvider = target;
    inferface.interfaceName = name;
    
    WKUserContentController *contentController = self.configuration.userContentController;
    NSArray *scripts = inferface.injectingScripts;
    for (NSString *source in scripts) {
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:source injectionTime:(WKUserScriptInjectionTimeAtDocumentEnd) forMainFrameOnly:NO];
        [contentController addUserScript:userScript];
    }
    [contentController setJSInterface:inferface];
    
}
- (void)webviewEvaluatingJavascript:(NSString *)script completeBlock:(void (^)(id _Nullable))complete{
    
    [self evaluateJavaScript:script completionHandler:^(id _Nullable para, NSError * _Nullable error) {
        if (complete) {
            complete(para);
        }
    }];
}

- (NSString *)provideJS2NativeCallForMessage:(NSString *)message{
    
    return [message stringByRemovingPercentEncoding];
}

@end
