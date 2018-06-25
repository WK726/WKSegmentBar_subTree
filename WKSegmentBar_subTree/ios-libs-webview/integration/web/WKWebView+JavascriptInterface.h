//
//  WKWebView+JavascriptInterface.h
//  gezilicai
//
//  Created by cuiyan on 16/11/9.
//  Copyright © 2016年 yuexue. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "IWebView.h"

@interface WKUserContentController(JavascriptInterface)<WKScriptMessageHandler>

@end

@interface WKWebView (JavascriptInterface)<IWebView,WKUIDelegate,WKNavigationDelegate>

@end
