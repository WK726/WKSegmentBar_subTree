
//
//  MJRefreshGeziGifHeader.m
//  gezilicai
//
//  Created by cuiyan on 2017/6/1.
//  Copyright © 2017年 yuexue. All rights reserved.
//

#import "MJRefreshGeziGifHeader.h"

#define DurationTime 3.

@interface MJRefreshGeziGifHeader()

@property (nonatomic, strong) NSMutableArray *idleImages;
@property (nonatomic, strong) NSMutableArray *normalImages;
@property (nonatomic, strong) NSMutableArray *refreshImages;

@end

@implementation MJRefreshGeziGifHeader

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

///** 普通闲置状态 */
//MJRefreshStateIdle = 1,
///** 松开就可以进行刷新的状态 */
//MJRefreshStatePulling,
///** 正在刷新中的状态 */
//    MJRefreshStateRefreshing,
//    /** 即将刷新的状态 */
//    MJRefreshStateWillRefresh,
//    /** 所有数据加载完毕，没有更多的数据了 */
//    MJRefreshStateNoMoreData
//};

+ (void) initGeziHeader:(MJRefreshGeziGifHeader *)header{
    
    header.mj_h = 55.;
    [header setImages:header.idleImages forState:(MJRefreshStateIdle)];
    [header setImages:header.normalImages forState:(MJRefreshStateWillRefresh)];
    [header setImages:header.normalImages forState:(MJRefreshStatePulling)];
    [header setImages:header.refreshImages duration:DurationTime forState:(MJRefreshStateRefreshing)];
    header.lastUpdatedTimeLabel.hidden = YES;
    
    // Hide the status
    header.stateLabel.hidden = YES;
}

+ (instancetype)headerWithRefreshingBlock:(MJRefreshComponentRefreshingBlock)refreshingBlock{
    
    MJRefreshGeziGifHeader *header = [super headerWithRefreshingBlock:refreshingBlock];
    [[self class]initGeziHeader:header];

    return header;
}

+ (instancetype)headerWithRefreshingTarget:(id)target refreshingAction:(SEL)action{
    
    MJRefreshGeziGifHeader *header = [super headerWithRefreshingTarget:target refreshingAction:action];
    [[self class]initGeziHeader:header];

    return header;
}

- (NSMutableArray *)idleImages{
    
    if (_idleImages == nil) {
        _idleImages = [NSMutableArray array];
        [_idleImages addObject:[UIImage imageNamed:@"gif_00000@3x.png"]];
    }
    return _idleImages;
}

- (NSMutableArray *)normalImages{
    
    if (_normalImages == nil) {
        
        _normalImages = [NSMutableArray array];
        
        for (NSInteger i = 0; i< 80; i++) {
            if (i%3 == 0) {
                NSMutableString *index = [NSMutableString stringWithFormat:@"%ld",(long)i];
                if (i< 10) {
                    [index insertString:@"0" atIndex:0];
                }
                [_refreshImages addObject:[UIImage imageNamed:[NSString stringWithFormat:@"gif_000%@@3x.png",index]]];
            }
        }
    }
    
    return _normalImages;
}

- (NSMutableArray *)refreshImages{
    
    if (_refreshImages == nil) {
        
        _refreshImages = [NSMutableArray array];
        
        for (NSInteger i = 0; i< 80; i++) {
            NSMutableString *index = [NSMutableString stringWithFormat:@"%ld",(long)i];
            if (i< 10) {
                [index insertString:@"0" atIndex:0];
            }
            [_refreshImages addObject:[UIImage imageNamed:[NSString stringWithFormat:@"gif_000%@@3x.png",index]]];
        }
    }
    
    return _refreshImages;
}

@end
