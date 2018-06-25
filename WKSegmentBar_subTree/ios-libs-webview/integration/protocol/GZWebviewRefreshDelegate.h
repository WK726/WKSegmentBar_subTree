
//
//  GZWebviewRefreshDelegate.h
//  gezilicai
//
//  Created by cuiyan on 17/3/27.
//  Copyright © 2017年 yuexue. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MJRefreshStateHeader;
@protocol GZWebviewRefreshDelegate <NSObject>

@optional
- (void)setRefreshHeader:(MJRefreshStateHeader *)header iforBlock:(void (^)(void))block;
- (BOOL)isRefreshing;
- (void)beginRefreshing;
- (void)beginRefreshingWithCompletionBlock:(void (^)(void))completionBlock;
- (void)endRefreshing;
- (void)endRefreshingWithCompletionBlock:(void (^)(void))completionBlock;

@end
