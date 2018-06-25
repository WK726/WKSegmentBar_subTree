//
//  GZBaseWebViewController+DisturbRequest.h
//  AFNetworkActivityLogger
//
//  Created by cyan on 2017/10/31.
//

#import "GZBaseWebViewController.h"

@interface GZBaseWebViewController (DisturbRequest)

- (BOOL)disturb_shouldStartRequest:(NSURL *)url;
- (void)disturb_requestDidLoad:(NSURL *)url;
- (void)disturb_requestDidFinishoad:(NSURL *)url;
- (void)disturb_requestDidFailLoad:(NSURL *)url;

@end
