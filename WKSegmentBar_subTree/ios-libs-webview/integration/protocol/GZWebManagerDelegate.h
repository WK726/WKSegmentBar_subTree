
//
//  GZWebViewControllerDelegate.h
//  gezilicai
//
//  Created by cuiyan on 17/2/23.
//  Copyright © 2017年 yuexue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol GZWebManagerDelegate <NSObject>

@optional
- (void)URLWillLoad:(NSURL *)url;
- (void)URLDidLoad:(NSURL *)url;
- (void)URLDidFinishLoad:(NSURL *)url;
- (void)URLDidFailLoad:(NSURL *)url error:(NSError * _Nullable)error;
- (void)documentTitleChanged:(NSString *)title;

- (NSDictionary *)requestHeaderField:(NSURL *)url;
- (void)cookieStoreDidChange:(WKHTTPCookieStore *)cookieStore;

@end

NS_ASSUME_NONNULL_END

