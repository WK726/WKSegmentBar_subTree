                                                                              //
//  GZUIWebViewController.m
//  gezilicai
//
//  Created by gslicai on 16/6/28.
//  Copyright © 2016年 yuexue. All rights reserved.
//

#import "GZUIWebViewController.h"
#import "UIWebView+JavascriptInterface.h"
#import "Masonry.h"
#import "GZBaseWebViewController+DisturbRequest.h"

@interface GZUIWebViewController()<UIWebViewDelegate,UIScrollViewDelegate>


@end

@implementation GZUIWebViewController

+ (instancetype)newInstanceWithUrl:(NSString *)url andDelegate:(NSObject<GZWebManagerDelegate> *)delegate{
    GZUIWebViewController* instance = [[GZUIWebViewController alloc]init];
    instance.url = url;
    instance.delegate = delegate;
    return instance;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.webviewType = UI_WebView;
    
    [self createUI];
    if (!self.disableRefresh) {
        __unsafe_unretained typeof(self) weakSelf = self;
        [self setRefreshHeader:nil iforBlock:^{
            [weakSelf.webView reload];
        }];
    }
    if (self.url != nil) {
        [self openURL:[NSURL URLWithString:self.url]];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.webViewAdapter && [self.webViewAdapter respondsToSelector:@selector(webAppearShouldScrollToTop:)]) {
        if ([self.webViewAdapter webAppearShouldScrollToTop:_webView.scrollView]) {
            _webView.scrollView.contentOffset = CGPointZero;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
}

- (void) viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    UIEdgeInsets inset = UIEdgeInsetsZero;
    if (self.webViewAdapter) {
        BOOL adjustInsetAutomatically = YES;
        if ([self.webViewAdapter respondsToSelector:@selector(webScrollViewAutomaticallyAdjustInsets)]) {
            adjustInsetAutomatically = [self.webViewAdapter webScrollViewAutomaticallyAdjustInsets];
        }
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
        if (!adjustInsetAutomatically && [self.webViewAdapter respondsToSelector:@selector(webViewInset:)]) {
            inset = [self.webViewAdapter webViewInset:self];
            _webView.scrollView.contentInset = inset;
        }
    }
    
    if (self.webViewAdapter && [self.webViewAdapter respondsToSelector:@selector(controllerViewLayoutSubviews)]) {
        [self.webViewAdapter controllerViewLayoutSubviews];
    }
}

#pragma mark --
- (void)createUI{
    _webView = [[UIWebView alloc]initWithFrame:CGRectZero];
    [_webView addJavascriptInterface:self.interfaceProvider forName:self.interfaceName];
    _webView.delegate = self;
    _webView.opaque = NO;
    _webView.dataDetectorTypes = UIDataDetectorTypeNone;
    _webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    _webView.scrollView.bounces = NO;
    _webView.scrollView.delegate = self;
    _webView.backgroundColor = [UIColor whiteColor];
    _webView.scrollView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_webView];
    
    UIEdgeInsets inset = UIEdgeInsetsZero;
    BOOL adjustInsetAutomatically = YES;
    if (self.webViewAdapter && [self.webViewAdapter respondsToSelector:@selector(webScrollViewAutomaticallyAdjustInsets)]) {
        adjustInsetAutomatically = [self.webViewAdapter webScrollViewAutomaticallyAdjustInsets];
    }
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
    
    
//    self.extendedLayoutIncludesOpaqueBars = YES;
//    if (@available(iOS 11.0, *)) {
//        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
//    } else {
//        self.automaticallyAdjustsScrollViewInsets = NO;
//    }
//    _webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 49, 0);

    __weak typeof(self) weakSelf = self;
    [_webView mas_makeConstraints:^(MASConstraintMaker *make) {
        __strong typeof(self) strongSelf = weakSelf;
        make.edges.equalTo(strongSelf.view).with.insets(inset);
    }];
    NSString *title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if(title != nil){
        BLYLogDebug(@"%@", title);
    }
    BLYLogDebug(@"%@",self.url);
}

- (void)dealloc{
    _webView.delegate = nil;
    _webView.scrollView.delegate = nil;

}

- (BOOL)canGoBack{
    
    return [_webView canGoBack];
}
- (void)goBack{
    if ([_webView canGoBack]) {
        [_webView goBack];
    }
}
- (void)goForward{
    if ([_webView canGoForward]) {
        [_webView goForward];
    }
}
- (void)reloadURL{
    [super reloadURL];
    [_webView reload];
}
- (void)openURL:(NSURL*)url{
    [super openURL:url];
    NSMutableURLRequest* targetRequest = [NSMutableURLRequest requestWithURL:url];
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestHeaderField:)]) {
        NSDictionary *fields = [self.delegate requestHeaderField:url];
        for (NSInteger i = 0; i < fields.allKeys.count; i++) {
            NSString *key = fields.allKeys[i];
            [targetRequest setValue:fields[key] forHTTPHeaderField:key];
        }
    }
    [_webView loadRequest:targetRequest];
}
- (void)stopLoading{
    [super stopLoading];
    [_webView stopLoading];
}
- (void)evaluateJavaScript:(NSString*)javaScriptString completeBlock:(void(^)(__nullable id obj))complete{
    NSString* response = [_webView stringByEvaluatingJavaScriptFromString:javaScriptString];
    if (complete) {
        complete(response);
    }
}

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL{
    
    [_webView loadHTMLString:string baseURL:baseURL];
}

#pragma mark -- scroll delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (self.webViewAdapter && [self.webViewAdapter respondsToSelector:@selector(webMonitorScroll:)]) {
        [self.webViewAdapter webMonitorScroll:scrollView];
    }
}

#pragma ------UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    BOOL res = [self disturb_shouldStartRequest:request.URL];
    if (!res && self.delegate && [self.delegate respondsToSelector:@selector(URLWillLoad:)]) {
        [self.delegate URLWillLoad:request.URL];
        return YES;
    }
    return NO;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    [self disturb_requestDidLoad:webView.request.URL];
    if (self.delegate && [self.delegate respondsToSelector:@selector(URLDidLoad:)]) {
        [self.delegate URLDidLoad:webView.request.URL];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    
    [self endRefreshing];
    [self disturb_requestDidFinishoad:webView.request.URL];
    if (self.delegate && [self.delegate respondsToSelector:@selector(URLDidFinishLoad:)]) {
        [self.delegate URLDidFinishLoad:webView.request.URL];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    
    [self endRefreshing];
    [self disturb_requestDidFailLoad:webView.request.URL];
    if (self.delegate && [self.delegate respondsToSelector:@selector(URLDidFailLoad:error:)]) {
        [self.delegate URLDidFailLoad:webView.request.URL error:error];
    }
}


@end


