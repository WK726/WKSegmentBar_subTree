//
//  GZWKWebViewController.h
//  gezilicai
//
//  Created by gslicai on 16/6/28.
//  Copyright © 2016年 yuexue. All rights reserved.
//

#import "GZBaseWebViewController.h"

@interface GZWKWebViewController : GZBaseWebViewController
- (void)syncCookiesSupportWithURL:(NSURL *)url completion:(void(^)(void))completion;
@property (nonatomic,strong) WKWebView* webView;
- (void) webViewInit;
@end
