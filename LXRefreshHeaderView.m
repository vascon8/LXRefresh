//
//  Created by xinliu on 14-10-22.
//  Copyright (c) 2014年 xinliu. All rights reserved.
//

#import "LXRefreshHeaderView.h"
#import "NSDate+LX.h"


NSString *const LXRefreshMsgNormal = @"继续下拉刷新数据";
NSString *const LXRefreshTimeKey = @"最近刷新时间";

@interface LXRefreshHeaderView ()

@end

@implementation LXRefreshHeaderView
#pragma mark - LifeCycle
+ (instancetype)header
{
    return [[self alloc]init];
}
- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.type = LXRefreshViewTypeHeader;
        self.state = LXRefreshStatusTypeNormal;
        
        [self setupTimeLable];
    }
    return self;
}
#pragma mark state
- (void)setState:(LXRefreshStatusType)state
{
    if (state == _state) return;
    
    switch (state) {
        case LXRefreshStatusTypeNormal:
            [self backToNormalState];
            break;
            
        case LXRefreshStatusTypePull:
            _statusLabel.text = LXRefreshMsgRelease;
            _arrowImageView.transform = CGAffineTransformMakeRotation(-M_PI);
            break;
            
        case LXRefreshStatusTypeRefreshing:
            [self showRefreshState];
            break;
            
        case LXRefreshStatusTypeWillRefresh:
            break;
            
        default:
            break;
    }
    
    _state = state;
    
}
- (void)backToNormalState
{
    if (_state == LXRefreshStatusTypeRefreshing) {
        [UIView animateWithDuration:kLXRefreshBackToNormalDur animations:^{
            _scrollView.contentInset = _scrollViewInitInset;
            _scrollView.contentOffset = CGPointMake(0.0, -_scrollViewInitOffsetHeight);
        }];
    }
    _statusLabel.text = LXRefreshMsgNormal;
    [_indicator stopAnimating];
    _indicator.hidden = YES;
    _arrowImageView.hidden = NO;
    _arrowImageView.transform = CGAffineTransformIdentity;
}
- (void)showRefreshState
{
    _statusLabel.text = LXRefreshMsgRefreshing;
    _arrowImageView.hidden = YES;
    _arrowImageView.transform = CGAffineTransformIdentity;
    _indicator.hidden = NO;
    [_indicator startAnimating];
    
    UIEdgeInsets inset = _scrollView.contentInset;
    inset.top += kLXRefreshViewHeight;
    _scrollView.contentInset = inset;
    _scrollView.contentOffset = CGPointMake(0.0, -inset.top);
    
    if ([self.delegate respondsToSelector:@selector(refreshViewBeginingRefresh:)]) {
        [self.delegate refreshViewBeginingRefresh:self];
    }
}
- (void)endRefreshWithSuccess:(BOOL)refreshSuccess
{
    [super endRefreshWithSuccess:refreshSuccess];
    
    if (refreshSuccess) [self updateTime:[NSDate date]];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kLXRefreshRefreshingDur * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.state = LXRefreshStatusTypeNormal;
    });
    
    if ([self.delegate respondsToSelector:@selector(refreshViewEndRefresh:)]) {
        [self.delegate refreshViewEndRefresh:self];
    }
}
- (void)updateTime:(NSDate *)date
{
    if (!date) return;
    
    NSDateFormatter *fmt = [[NSDateFormatter alloc]init];
    fmt.dateFormat = @"HH:mm";
    NSString *timeStr = [NSString stringWithFormat:@"最近更新:%@",[fmt stringFromDate:date]];
    _timeLabel.text = timeStr;
    
    [[NSUserDefaults standardUserDefaults]setObject:date forKey:LXRefreshTimeKey];
    [[NSUserDefaults standardUserDefaults]synchronize];
}
- (void)setupTimeLable
{
    NSDate *lastUpdateTime = [[NSUserDefaults standardUserDefaults]objectForKey:LXRefreshTimeKey];
    if (!lastUpdateTime) lastUpdateTime = [NSDate dateWithTimeIntervalSince1970:1.0];
    
    NSString *timeStr = Nil;
    NSDateFormatter *fmt = [[NSDateFormatter alloc]init];
    fmt.dateFormat = @"HH:mm";
    if ([NSDate isToday:lastUpdateTime]) {
        timeStr = [NSString stringWithFormat:@"今天 %@",[fmt stringFromDate:lastUpdateTime]];
    }
    else if([NSDate isYesterday:lastUpdateTime]){
        timeStr = [NSString stringWithFormat:@"昨天 %@",[fmt stringFromDate:lastUpdateTime]];
    }
    else{
        fmt.dateFormat = @"yyyy-MM-dd HH:mm";
        timeStr = [NSString stringWithFormat:@"%@",[fmt stringFromDate:lastUpdateTime]];
    }

    _timeLabel.text = [NSString stringWithFormat:@"最近更新:%@",timeStr];
}

@end
