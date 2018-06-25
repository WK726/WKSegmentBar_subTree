//
//  GZWKWebViewController.m
//  gezilicai
//
//  Created by gslicai on 16/6/28.
//  Copyright © 2016年 yuexue. All rights reserved.
//

#import "GZWKWebViewController.h"
#import <WebKit/WebKit.h>
#import "WKWebView+JavascriptInterface.h"
#import "JavascriptInterface.h"
#import "Masonry.h"
#import <objc/runtime.h>
#import "GZBaseWebViewController+DisturbRequest.h"
#import "AppTools.h"
#import "WkSharedProcessPool.h"
#import "UserStateCookieFilter.h"
#import "HostProvider.h"
#define FETCH_TITLE_USE_KVO
#define Use_Frame_Layout    //webview layout方式

@interface GZWKWebViewController()<WKUIDelegate,WKNavigationDelegate,WKScriptMessageHandler,UIScrollViewDelegate,WKHTTPCookieStoreObserver>{
    WKWebViewConfiguration *_webViewConfiguration;
    UIProgressView *_progressBar;
    dispatch_source_t _progressTimer;
}

@property (nonatomic,strong) NSMutableArray *wekKitCookies;
@property (atomic,assign) BOOL isShowKeyboard;
@property (nonatomic,strong) UserStateCookieFilter* cookieFilter;
@end

@implementation GZWKWebViewController

+ (instancetype)newInstanceWithUrl:(NSString *)url andDelegate:(NSObject<GZWebManagerDelegate> *)delegate{
    GZWKWebViewController* instance = [[GZWKWebViewController alloc]init];
    instance.url = url;
    instance.delegate = delegate;
    return instance;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.webviewType = WK_WebView;
    
    [self webViewInit];
    if (!self.disableRefresh) {
        __unsafe_unretained typeof(self) weakSelf = self;
        [self setRefreshHeader:nil iforBlock:^{
            [weakSelf.webView reload];
        }];
    }
    if (!self.disableProgress) {
        [self addProgressBar];
    }
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyBoardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyBoardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyBoardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyBoardDidHide:) name:UIKeyboardDidHideNotification object:nil];
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(nativeCookieChanged:) name:NSHTTPCookieManagerCookiesChangedNotification object:nil];
    [self openURL:[NSURL URLWithString:self.url]];
    BLYLogDebug(@"%@",self.url);
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
#ifdef Use_Frame_Layout
    
#else
    [self adjustWebViewContentInsets];
#endif
    if (self.webViewAdapter && [self.webViewAdapter respondsToSelector:@selector(webAppearShouldScrollToTop:)]) {
        if ([self.webViewAdapter webAppearShouldScrollToTop:_webView.scrollView]) {
            _webView.scrollView.contentOffset = CGPointZero;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
#ifdef Use_Frame_Layout
    
#else
    [self adjustWebViewContentInsets];
#endif
    
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (void)viewSafeAreaInsetsDidChange{
    [super viewSafeAreaInsetsDidChange];
#ifdef Use_Frame_Layout
    [self adjustWebViewContentInsets];
#else
    [self adjustWebViewContentInsets];
#endif
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
#ifdef Use_Frame_Layout
    [self adjustWebViewContentInsets];
#else
    
#endif
}

- (void) viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    if (self.webViewAdapter && [self.webViewAdapter respondsToSelector:@selector(controllerViewLayoutSubviews)]) {
        [self.webViewAdapter controllerViewLayoutSubviews];
    }
}

- (void) webViewInit{
    WKUserContentController *contentController = [[WKUserContentController alloc] init];
    [contentController addScriptMessageHandler:self name:self.interfaceName];
    
    _webViewConfiguration = [[WKWebViewConfiguration alloc] init];
    _webViewConfiguration.userContentController = contentController;
    _webViewConfiguration.processPool = [WkSharedProcessPool sharedProcessPool];
    
    //    WKUserScript * cookieScript = [[WKUserScript alloc] initWithSource: @"document.cookie ='TeskCookieKey1=TeskCookieValue1';document.cookie = 'TeskCookieKey2=TeskCookieValue2';"injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    //    [contentController addUserScript:cookieScript];
    //    WKWebViewConfiguration* webViewConfig = WKWebViewConfiguration.new;
    //    webViewConfig.userContentController = userContentController;
    //    WKWebView * webView = [[WKWebView alloc] initWithFrame:CGRectMake(/*set your values*/) configuration:webViewConfig];
    
    
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:_webViewConfiguration];
    [_webView addJavascriptInterface:self.interfaceProvider forName:self.interfaceName];
    _webView.navigationDelegate = self;
    _webView.UIDelegate = self;
    //因为前端路由某些 bug, 暂时禁用掉
    _webView.allowsBackForwardNavigationGestures = NO;
    _webView.scrollView.bounces = NO;
    _webView.scrollView.contentInset = UIEdgeInsetsZero;
    _webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    _webView.scrollView.layer.masksToBounds = NO;
    _webView.scrollView.delegate = self;
    _webView.backgroundColor = [UIColor whiteColor];
    _webView.scrollView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_webView];
    
#ifdef Use_Frame_Layout
    [self adjustWebViewContentInsets];
#else
    //webView 延伸到 NavigationBar 和 tabbar, 如果 H5 内容没有延伸到下面,可以修改 contentInset.
    __weak typeof(self) weakSelf = self;
    [_webView mas_updateConstraints:^(MASConstraintMaker *make) {
        __strong typeof(self) strongSelf = weakSelf;
        make.edges.equalTo(strongSelf.view);
    }];
#endif

    
#ifdef FETCH_TITLE_USE_KVO
    [_webView addObserver:self
               forKeyPath:@"title"
                  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                  context:nil];
#endif
    if (@available(iOS 11.0, *)) {
        WKHTTPCookieStore *cookieStore = self.webView.configuration.websiteDataStore.httpCookieStore;
        [cookieStore addObserver:self];
    } else {
        // Fallback on earlier versions
    }
}

- (void)adjustWebViewContentInsets{
    BOOL adjustInsetAutomatically = YES;
    UIEdgeInsets inset = UIEdgeInsetsZero;
    if (self.webViewAdapter && [self.webViewAdapter respondsToSelector:@selector(webScrollViewAutomaticallyAdjustInsets)]) {
        adjustInsetAutomatically = [self.webViewAdapter webScrollViewAutomaticallyAdjustInsets];
    }
    // 设置layout方式
    if (adjustInsetAutomatically) {
        if (@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
        }else{
            self.automaticallyAdjustsScrollViewInsets = YES;
        }
    }else{
        if (@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }else{
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
    }
    if (!adjustInsetAutomatically && self.webViewAdapter && [self.webViewAdapter respondsToSelector:@selector(webViewInset:)]) {
        inset = [self.webViewAdapter webViewInset:self];
    }
#ifdef Use_Frame_Layout
    __weak typeof(self) weakSelf = self;
    [_webView mas_updateConstraints:^(MASConstraintMaker *make) {
        __strong typeof(self) strongSelf = weakSelf;
        make.edges.equalTo(strongSelf.view).with.insets(inset);
    }];
#else
    if (!adjustInsetAutomatically) {
        _webView.scrollView.contentInset = inset;
        //    [self.view layoutSubviews];
        [self.view setNeedsLayout];
    }
#endif
}

/**
 1、暂时不考虑302跳转
 2、http/wk 同步cookie，NSHTTPCookieStorage是中转站
 wk2native：notificate to httpcookie and share with other wkwebview by 'progcess Pool'
 native2wk：set when loadurl and 显性通知
 
 */
- (void)setCookeis:(NSArray <NSHTTPCookie *>*)cookies url:(NSURL *)url completionHandler:(void(^)(void))completion{
    if (@available(iOS 11.0, *)) {
      
        __block NSInteger fixedCount = 0;
        WKHTTPCookieStore *cookieStore = self.webView.configuration.websiteDataStore.httpCookieStore;
        BOOL hasSessionId = NO;
        for (int i = 0; i < cookies.count; i++) {
            NSHTTPCookie* cookie = cookies[i];
            if ([cookie.name isEqualToString:@"sessionid"] && [[HostProvider globalHost] containsString:cookie.domain]) {
                hasSessionId = YES;
            }
        }
        //hack 一下
        if (hasSessionId == NO) {
            NSMutableDictionary* cookieProperties = [NSMutableDictionary dictionary];
            [cookieProperties setObject:@"sessionid" forKey:NSHTTPCookieName];
            [cookieProperties setObject:@"----------" forKey:NSHTTPCookieValue];
            [cookieProperties setObject:[NSDate dateWithTimeIntervalSinceNow:2048] forKey:NSHTTPCookieExpires];
            [cookieProperties setObject:[NSURL URLWithString:[HostProvider globalHost]].host forKey:NSHTTPCookieDomain];
            [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
            [cookieProperties setObject:@"true" forKey:@"HttpOnly"];
            NSHTTPCookie* fakeCookie = [[NSHTTPCookie alloc]initWithProperties:cookieProperties];
            [cookieStore setCookie:fakeCookie completionHandler:^{
                
            }];
        }
        if (cookies && cookies.count) {
            
            for (int i = 0; i < cookies.count; i++) {
                NSHTTPCookie* cookie = cookies[i];
                //                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                //                if (cookie.name)
                //                    [dict setObject:cookie.name forKey:NSHTTPCookieName];
                //                if (cookie.value)
                //                    [dict setObject:cookie.value forKey:NSHTTPCookieValue];
                //                if (cookie.expiresDate)
                //                    [dict setObject:cookie.expiresDate forKey:NSHTTPCookieExpires];
                //                if (cookie.domain)
                //                    [dict setObject:cookie.domain forKey:NSHTTPCookieDomain];
                //                [dict setObject:@"/" forKey:NSHTTPCookiePath];
                //                [dict setObject:@"TRUE" forKey:NSHTTPCookieSecure];
                //                [dict setObject:@(cookie.version) forKey:NSHTTPCookieVersion];
                
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: cookie.properties];
                if ([cookie.name isEqualToString:@"sessionid"] && !cookie.isHTTPOnly) {
                    [dict setObject:@"true" forKey:@"HttpOnly"];
                }
                NSHTTPCookie *willSyncCookie = [NSHTTPCookie cookieWithProperties:dict];
//                cookieStore.getAllCookies() { (cookies) in
//                    for cookie in cookies {
//                        // Find the login cookie
//                    }
//                }
                [cookieStore setCookie:willSyncCookie completionHandler:^{
                    fixedCount ++;
                    if (fixedCount == cookies.count) {
                        if (completion) {
                            completion();
                        }
                    }
                }];
            }

        }else if(completion){
            completion();
            
        }
    } else {
        // Fallback on earlier versions
    }
}

- (void)syncCookiesSupportWithURL:(NSURL *)url completion:(void(^)(void))completion{
    //
    if (@available(iOS 11.0, *)) {
        //        //从 http 同步cookie到webCookiestore
        NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        [self setCookeis:[cookieJar cookies] url:url completionHandler:^{
            if (completion) {
                completion();
            }
        }];
    }else if (completion){
        completion();
    }
}

#pragma mark --
- (void)cookiesDidChangeInCookieStore:(WKHTTPCookieStore *)cookieStore{ //考虑拿出来，以免当前页面消失时，setCookie还未完成
    
    [cookieStore getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
        
    }];
   
    [cookieStore getAllCookies:^(NSArray<NSHTTPCookie *> * cookies) {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//        [cookieStorage setCookies:cookies forURL:[NSURL URLWithString:[HostProvider globalHost]] mainDocumentURL:[NSURL URLWithString:[HostProvider globalHost]]];
        //判断是否需要清除掉 sessionid, 如果在当前服务器没有 sessionid, 就清空 cookie
        //目前的选择是 native 不要清空 sessionid, 因为 sessionid 已经无效了
        BOOL hasSessionId = NO;
        for (int i = 0; i < cookies.count; i++) {
            NSHTTPCookie* cookie = cookies[i];
            if ([cookie.name isEqualToString:@"sessionid"] && [[HostProvider globalHost] containsString:cookie.domain]) {
                hasSessionId = YES;
            }
        }
        if (hasSessionId == NO) {
            //[cookieStorage removeCookiesSinceDate:[NSDate dateWithTimeIntervalSince1970:0]];
        }else{
            for (int i = 0; i < cookies.count; i++) {
                NSHTTPCookie* cookie = cookies[i];
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: cookie.properties];
                if ([cookie.name isEqualToString:@"sessionid"] && !cookie.isHTTPOnly) {
                    [dict setObject:@"true" forKey:@"HttpOnly"];
                }

                cookie = [NSHTTPCookie cookieWithProperties:dict];
                [cookieStorage setCookie:cookie];
            }
        }
    }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(cookieStoreDidChange:)]) {
        [self.delegate cookieStoreDidChange:cookieStore];
    }
}

- (void)addProgressBar{
    _progressBar = [[UIProgressView alloc] initWithFrame:(CGRectMake(0, 0, CGRectGetWidth(_webView.bounds), 1.))];
    _progressBar.hidden = YES;
    _progressBar.transform = CGAffineTransformMakeScale(1.0f, 1.5f);
    [self.webView addSubview:_progressBar];
}

- (void)startProgress:(CGFloat)progress{
    if (!self.disableProgress && !_progressBar) {
        [self addProgressBar];
    }
    if (_progressBar) {
        [_progressBar setHidden:NO];
        
        _progressTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_progressTimer, DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC, 0.2 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(_progressTimer, ^{
            [_progressBar setProgress:progress animated:YES];
        });
        // Start the timer
        dispatch_resume(_progressTimer);
    }
}
- (void)endProgress{
    if (_progressTimer) {
        dispatch_source_cancel(_progressTimer);
    }
    if (_progressBar) {
        [UIView animateWithDuration:.25f delay:0.3f options:(UIViewAnimationOptionCurveEaseOut) animations:^{
            _progressBar.transform = CGAffineTransformMakeScale(1.0f, 1.4f);
            _progressBar.progress = 1.;
        } completion:^(BOOL finished) {
            [_progressBar setHidden:YES];
        }];
    }
}

- (void)dealloc{
    if (_progressTimer) {
        dispatch_source_cancel(_progressTimer);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:NSHTTPCookieManagerCookiesChangedNotification];
    
    if (_webView) {
        [_webView removeObserver:self forKeyPath:@"title"];
        if (@available(iOS 11.0, *)) {
            WKHTTPCookieStore *cookieStore = self.webView.configuration.websiteDataStore.httpCookieStore;
            if (cookieStore) {
                [cookieStore removeObserver:self];
            }
        }
        _webView.UIDelegate = nil;
        _webView.scrollView.delegate = nil;
    }
}

#pragma mark --
- (BOOL)canGoBack{
    
    return [_webView canGoBack];
}
- (void)goBack{
    if ([_webView canGoBack]) {
        WKBackForwardListItem *item = [_webView.backForwardList backItem];
        if (item) {
            [_webView goToBackForwardListItem:item];
        }else{
            [_webView goBack];
        }
    }
}
- (BOOL)canGoForward{
    return [_webView canGoForward];
}
- (void)goForward{
    if ([_webView canGoForward]) {
        WKBackForwardListItem *item = [_webView.backForwardList forwardItem];
        if (item) {
            [_webView goToBackForwardListItem:item];
        }else{
            [_webView goForward];
        }
    }
}
- (void)reloadURL{
    [super reloadURL];
    __weak typeof(self) weakself = self;
    
    [self syncCookiesSupportWithURL:[NSURL URLWithString:self.url] completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.webView reload];
        });
    }];
}
- (void)openURL:(NSURL*)url{
    [super openURL:url];
    __weak typeof(self) weakself = self;
    [self syncCookiesSupportWithURL:url completion:^{
//        NSMutableURLRequest* targetRequest = [NSMutableURLRequest requestWithURL:url];
        NSMutableURLRequest* targetRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:4.0];
        if (weakself.delegate && [weakself.delegate respondsToSelector:@selector(requestHeaderField:)]) {
            NSDictionary *fields = [weakself.delegate requestHeaderField:url];
            for (NSInteger i = 0; i < fields.allKeys.count; i++) {
                NSString *key = fields.allKeys[i];
                [targetRequest setValue:fields[key] forHTTPHeaderField:key];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //            NSString *cookie = [self readCurrentCookie];
            //            [targetRequest setValue:cookie forHTTPHeaderField:@"Cookie"];
            [weakself.webView loadRequest:targetRequest];
        });
    }];
//           NSMutableURLRequest* targetRequest = [NSMutableURLRequest requestWithURL:url];
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//        //            NSString *cookie = [self readCurrentCookie];
//        //            [targetRequest setValue:cookie forHTTPHeaderField:@"Cookie"];
//        [weakself.webView loadRequest:targetRequest];
//    });
}

//-(NSString *)readCurrentCookie{
//    NSMutableDictionary *cookieDic = [NSMutableDictionary dictionary];
//    NSMutableString *cookieValue = [NSMutableString stringWithFormat:@""];
//    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//    for (NSHTTPCookie *cookie in [cookieJar cookies]) {
//        [cookieDic setObject:cookie.value forKey:cookie.name];
//    }
//
//    // cookie重复，先放到字典进行去重，再进行拼接
//    for (NSString *key in cookieDic) {
//        NSString *appendString = [NSString stringWithFormat:@"%@=%@;", key, [cookieDic valueForKey:key]];
//        [cookieValue appendString:appendString];
//    }
//    return cookieValue;
//}

- (void)stopLoading{
    [super stopLoading];
    [_webView stopLoading];
}
- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL{
    
    [_webView loadHTMLString:string baseURL:baseURL];
}
- (void)evaluateJavaScript:(NSString*)javaScriptString completeBlock:(void(^)(__nullable id obj))complete{
    [_webView evaluateJavaScript:javaScriptString completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
        if (complete != nil) {
            complete(obj);
        }
    }];
}

#pragma mark --
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context{
    if([keyPath isEqualToString:@"title"]){
        NSString *newTitle = [change objectForKey:@"new"];
        if(newTitle != nil){
            if(![newTitle hasPrefix:@"{"] && ![newTitle hasSuffix:@"}"]){
                BLYLogDebug(@"%@", newTitle);
                if (self.delegate && [self.delegate respondsToSelector:@selector(documentTitleChanged:)]) {
                    [self.delegate documentTitleChanged:newTitle];
                }
            }
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -- scrollview delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (self.webViewAdapter && [self.webViewAdapter respondsToSelector:@selector(webMonitorScroll:)]) {
        [self.webViewAdapter webMonitorScroll:scrollView];
    }
    
    //bug fix iOS11 上面,js 使用 window.scrollTo() 的 bug
//    if (@available(iOS 11,*)) {
//        if (self.isShowKeyboard == NO && scrollView.isDragging == NO && scrollView.isDecelerating == NO && (scrollView.contentOffset.x < scrollView.adjustedContentInset.left || scrollView.contentOffset.y > - scrollView.adjustedContentInset.top)) {
//            scrollView.contentOffset = CGPointMake(scrollView.adjustedContentInset.left,-scrollView.adjustedContentInset.top);
//        }
//    }
}

- (void)scrollViewDidChangeAdjustedContentInset:(UIScrollView *)scrollView{
    NSLog(@"%@",scrollView);
}
# pragma mark - scriptmessage handler
- (void) userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    
}

# pragma mark - navigationDelegate

- (void) webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    NSURL *URL = navigationAction.request.URL;
    BOOL res = NO;
#ifdef FETCH_TITLE_USE_KVO
#else
    res = [self disturb_shouldStartRequest:URL];
#endif
    if (!res && self.delegate && [self.delegate respondsToSelector:@selector(URLWillLoad:)]) {
        [self.delegate URLWillLoad:URL];
        decisionHandler(WKNavigationActionPolicyAllow);
    }else{
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void) webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void) webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    if (![self isRefreshing]) {
        __weak typeof(WKWebView*) weakWebview = webView;
        [self startProgress:weakWebview.estimatedProgress];
    }
}

- (void) webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    if (self.delegate && [self.delegate respondsToSelector:@selector(URLDidFailLoad:error:)]) {
        [self.delegate URLDidFailLoad:webView.URL error:error];
    }
}
- (void) webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
#ifdef FETCH_TITLE_USE_KVO
#else
    [self disturb_requestDidLoad:webView.URL];
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(URLDidLoad:)]) {
        [self.delegate URLDidLoad:webView.URL];
    }
}

- (void) webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    
    [self endRefreshing];
    [self endProgress];
#ifdef FETCH_TITLE_USE_KVO
    if(_webView.title && _webView.title.length > 0){
        NSString *newTitle = _webView.title;
        if (self.delegate && [self.delegate respondsToSelector:@selector(documentTitleChanged:)]) {
            [self.delegate documentTitleChanged:newTitle];
        }
    }
#else
    [self disturb_requestDidFinishoad:webView.URL];
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(URLDidFinishLoad:)]) {
        [self.delegate URLDidFinishLoad:webView.URL];
    }
}
- (void) webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    
    [self endRefreshing];
    [self endProgress];
#ifdef FETCH_TITLE_USE_KVO
#else
    [self disturb_requestDidFailLoad:webView.URL];
#endif
    if (self.delegate && [self.delegate respondsToSelector:@selector(URLDidFailLoad:error:)]) {
        [self.delegate URLDidFailLoad:webView.URL error:error];
    }
}

- (void) webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
    
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    [self openURL:[NSURL URLWithString:self.url]];
}

#pragma ------WKUIDelegate
- (void) webViewDidClose:(WKWebView *)webView{
}

#pragma Keyboard
- (void)keyBoardWillShow:(NSNotification*)noti{
    if (self.isShowKeyboard == NO) {
        self.isShowKeyboard = YES;
    }
}

- (void)keyBoardDidShow:(NSNotification*)noti{
    
}

- (void)keyBoardWillHide:(NSNotification*)noti{
    if (self.isShowKeyboard == YES) {
        self.isShowKeyboard = NO;
    }
}

- (void)keyBoardDidHide:(NSNotification*)noti{
    
}
@end

