//
//  WkSharedProcessPool.m
//  AFNetworkActivityLogger
//
//  Created by cyan on 2017/11/9.
//

#import "WkSharedProcessPool.h"

@implementation WkSharedProcessPool

static WkSharedProcessPool *sharedProcessPool;
+ (WkSharedProcessPool *)sharedProcessPool{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedProcessPool = [[WkSharedProcessPool alloc] init];
    });
    return sharedProcessPool;
}

@end
