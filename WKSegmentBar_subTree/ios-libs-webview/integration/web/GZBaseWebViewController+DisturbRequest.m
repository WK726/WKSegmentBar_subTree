//
//  GZBaseWebViewController+DisturbRequest.m
//  AFNetworkActivityLogger
//
//  Created by cyan on 2017/10/31.
//

#import "GZBaseWebViewController+DisturbRequest.h"

@implementation GZBaseWebViewController (DisturbRequest)

- (BOOL)navigationTitleRequest:(NSURL*)requestUrl{ 
    
    BOOL res = NO;
    NSURL *url = requestUrl;
    if ([url.scheme.lowercaseString isEqualToString:self.interfaceName.lowercaseString]) {
        NSString* absUrl = url.absoluteString;
        if ([absUrl.lowercaseString isEqualToString:[NSString stringWithFormat:@"%@://title",self.interfaceName.lowercaseString]]) {
            res = YES;
            [self setViewControllerTitle];
        }
    }
    return res;
}
- (void)setViewControllerTitle{
    __weak typeof(self) weakSelf = self;
    [self evaluateJavaScript:@"document.title" completeBlock:^(id  _Nullable obj) {
        NSString *newTitle = (NSString *)obj;
        if(newTitle && ![newTitle hasPrefix:@"{"] && ![newTitle hasSuffix:@"}"]){
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(documentTitleChanged:)]) {
                [weakSelf.delegate documentTitleChanged:newTitle];
            }
        }
    }];
}

#pragma mark --
- (BOOL)disturb_shouldStartRequest:(NSURL *)url{
    return [self navigationTitleRequest:url];
}
- (void)disturb_requestDidLoad:(NSURL *)url{
    
}
- (void)disturb_requestDidFinishoad:(NSURL *)url{
    NSString *observerTitleEvaluateString = [NSString stringWithFormat:@"var target = document.querySelector('head > title'); window.observer = new window.WebKitMutationObserver(function(mutations) {mutations.forEach(function(mutation) {document.location.href='%@://title';});});observer.observe(target, {subtree: true,characterData: true,childList: true});",self.interfaceName];
    [self evaluateJavaScript:observerTitleEvaluateString completeBlock:nil];
    [self setViewControllerTitle];
}
- (void)disturb_requestDidFailLoad:(NSURL *)url{
    
    [self setViewControllerTitle];
}

@end

