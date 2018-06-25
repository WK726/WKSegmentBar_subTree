//
//  GZWebViewDelegate.h
//  gezilicai
//
//  Created by gslicai on 16/6/28.
//  Copyright © 2016年 yuexue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol GZWebViewDelegate <NSObject>

@required
- (UIEdgeInsets)webViewInset:(UIViewController*)viewController;

@optional
- (void)webMonitorScroll:(UIScrollView *)scrollview;
- (BOOL)webAppearShouldScrollToTop:(UIScrollView *)scrolview;
- (void)controllerViewLayoutSubviews;


/**
 * @brief 遵循scrollViewInsetAdjustAutomatically或者 webViewInset设置的值,defaul is autoSet
 */
- (BOOL)webScrollViewAutomaticallyAdjustInsets;

@end
