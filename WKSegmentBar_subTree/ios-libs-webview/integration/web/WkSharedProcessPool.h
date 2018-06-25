//
//  WkSharedProcessPool.h
//  AFNetworkActivityLogger
//
//  Created by cyan on 2017/11/9.
//

#import <WebKit/WebKit.h>

@interface WkSharedProcessPool : WKProcessPool
+ (WkSharedProcessPool *)sharedProcessPool;
@end
