//
//  GZBaseWebViewController.m
//  gezilicai
//
//  Created by gslicai on 16/6/29.
//  Copyright © 2016年 yuexue. All rights reserved.
//

#import "GZBaseWebViewController.h"
#import "MJRefresh.h"
#import <WebKit/WebKit.h>

//#define ENABLE_WEB_EDGEPAN

@interface GZBaseWebViewController()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *webview;
@property (nonatomic, strong) UIScrollView *webScrollview;

@property (nonatomic,strong) NSMutableArray *snapShots;
@property (nonatomic,strong) UIImageView *snapshotView;
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *addEdgePan;

@end

@implementation GZBaseWebViewController

+ (instancetype) newInstanceWithUrl:(NSString *)url andDelegate:(NSObject<GZWebManagerDelegate>*)__weak delegate{
    GZBaseWebViewController* instance = [[GZBaseWebViewController alloc]init];
    instance.delegate = delegate;
    instance.url = url;
    return instance;
}

- (instancetype)init{
    
    if (self = [super init]) {
#ifdef ENABLE_WEB_EDGEPAN
        self.snapShots = [NSMutableArray array];
#endif
        self.webviewType = UI_WebView;
        self.disableRefresh = YES;
        self.disableProgress = YES;
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
#ifdef ENABLE_WEB_EDGEPAN
    id target = self.navigationController.interactivePopGestureRecognizer.delegate;
    UIScreenEdgePanGestureRecognizer *edgePan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:target action:@selector(handleNavigationTransition:)];
    edgePan.enabled = 0;
    edgePan.edges = UIRectEdgeLeft;
    edgePan.delegate  = self;
    [self.view addGestureRecognizer:edgePan];
    self.addEdgePan = edgePan;
#endif
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = 1;
}

- (BOOL)canGoBack{
    return NO;
}
- (void)goBack{
    
}
- (BOOL)canGoForward{
    return NO;
}
- (void)goForward{
    
}
- (void)reloadURL{
    
}
- (void)stopLoading{
    
}
- (void)openURL:(NSURL*)url{
    
}
- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL{
    
}
- (void)evaluateJavaScript:(NSString*)javaScriptString completeBlock:(void(^)(__nullable id obj))complete{
    
}

- (UIView *)webview{
    if (_webviewType == UI_WebView) {
        UIWebView *view = [self valueForKey:@"_webView"];
        return view;
    }else if (_webviewType == WK_WebView) {
        WKWebView *view = [self valueForKey:@"_webView"];
        return view;
    }
    return nil;
}
- (UIScrollView *)webScrollview{
    
    if (_webviewType == UI_WebView) {
        UIWebView *view = [self valueForKey:@"_webView"];
        return view.scrollView;
    }else if (_webviewType == WK_WebView) {
        WKWebView *view = [self valueForKey:@"_webView"];
        return view.scrollView;
    }
    return nil;
}

#pragma mark -- refreshing
- (void)setRefreshHeader:(UIView *)header iforBlock:(void (^)(void))block{
    self.webScrollview.bounces = YES;
    if (header) {
        self.webScrollview.mj_header = (MJRefreshHeader *)header;
    }else if (block){
        self.webScrollview.mj_header = [MJRefreshStateHeader headerWithRefreshingBlock:block];
    }
}

- (BOOL)isRefreshing{
    BOOL refreshing = NO;
    if (self.webScrollview.mj_header && [self.webScrollview.mj_header isRefreshing]) {
        refreshing = YES;
    }
    return refreshing;
}

- (void)beginRefreshing{
    if (self.webScrollview.mj_header && ![self.webScrollview.mj_header isRefreshing]) {
        [self.webScrollview.mj_header beginRefreshing];
    }
}

- (void)endRefreshing{
    if (self.webScrollview.mj_header && [self.webScrollview.mj_header isRefreshing]) {
        [self.webScrollview.mj_header endRefreshing];
    }
}

#pragma mark -- forward/backforwardPage
- (void)forwardPage{
 
    [_snapShots addObject:[self capture]];
    self.addEdgePan.enabled = 1;
}

- (void)backForwardPage{
    
    if (_snapShots && _snapShots.count) {
        [_snapShots removeLastObject];
        if (!_snapShots.count) {
            self.addEdgePan.enabled = 0;
        }
    }
}

- (UIImage *)capture
{
    UIView *willRenderView = [[UIApplication sharedApplication]keyWindow].rootViewController.view;
    UIGraphicsBeginImageContextWithOptions(willRenderView.bounds.size, willRenderView.opaque, 0.0);
    [willRenderView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

- (void)handleNavigationTransition:(UIScreenEdgePanGestureRecognizer *)pan{
    
#define ARate 1/3.
#define BRate 1/3.
#define AniTime .5
    
    if (!_snapShots.count) {
        return;
    }
    
    //当前view右移， 右移属性必须和navigationcontroller相关 。。
    CGPoint panPoint = [pan locationInView:nil];
    CGFloat basewebController_screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat basewebController_screenHeight = [UIScreen mainScreen].bounds.size.height;
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{
            
            self.startPoint = [pan locationInView:self.navigationController.view];
            
            UIImageView *snapView = [[UIImageView alloc] initWithFrame:(CGRectMake(-basewebController_screenWidth*ARate, 0, basewebController_screenWidth,basewebController_screenHeight))];
            snapView.image = [_snapShots lastObject];
            self.snapshotView = snapView;
            

            [[UIApplication sharedApplication].keyWindow addSubview:snapView];
            [[UIApplication sharedApplication].keyWindow sendSubviewToBack:snapView];
        }
            break;
        case UIGestureRecognizerStateChanged:{
            
            CGFloat x = panPoint.x-_startPoint.x;
            x = x < 0 ? 0 : x;
            self.snapshotView.transform = CGAffineTransformMakeTranslation(x * ARate, 0);
            self.navigationController.view.transform = CGAffineTransformMakeTranslation(x, 0);
        }
            break;
        case UIGestureRecognizerStateEnded:{
            
            if (panPoint.x > basewebController_screenWidth * BRate) {
                
            	[UIView animateWithDuration:(basewebController_screenWidth-panPoint.x)/basewebController_screenWidth*AniTime animations:^{
                   
                    [self goBack];
                    
                    self.snapshotView.transform = CGAffineTransformMakeTranslation(basewebController_screenWidth*ARate , 0);
                    self.navigationController.view.transform = CGAffineTransformMakeTranslation(basewebController_screenWidth, 0);
                }completion:^(BOOL finished) {
                    
                    self.navigationController.view.transform = CGAffineTransformMakeTranslation(0, 0);
                    [self.snapshotView removeFromSuperview];
                }];
                
            }else{
                [UIView animateWithDuration:panPoint.x/basewebController_screenWidth*AniTime animations:^{
                    self.snapshotView.transform  = CGAffineTransformMakeTranslation(-basewebController_screenWidth*ARate, 0);
                    self.navigationController.view.transform = CGAffineTransformMakeTranslation(0, 0);
                }completion:^(BOOL finished) {
                    [self.snapshotView removeFromSuperview];
                }];
            }
        }
            break;
        case UIGestureRecognizerStateCancelled:{
            [UIView animateWithDuration:panPoint.x/basewebController_screenWidth*AniTime animations:^{
                self.snapshotView.transform  = CGAffineTransformMakeTranslation(-basewebController_screenWidth*ARate, 0);
                self.navigationController.view.transform = CGAffineTransformMakeTranslation(0, 0);
            }completion:^(BOOL finished) {
                [self.snapshotView removeFromSuperview];
            }];
        }
            break;
        default:
            break;
    }
}

#pragma mark -- ges delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    return YES;
}

#pragma mark -- ges delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}


@end
