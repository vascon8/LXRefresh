//
//  LXRefreshView.m
//  0926新浪微博
//
//  Created by xinliu on 14-10-22.
//  Copyright (c) 2014年 xinliu. All rights reserved.
//

#import "LXRefreshView.h"
#import "NSDate+LX.h"

NSString *const LXRefreshMsgNormal = @"继续下拉刷新数据";
NSString *const LXRefreshMsgRefreshing = @"正在刷新数据...";
NSString *const LXRefreshMsgRelease = @"松开立即刷新";

#define kLXRefreshViewMargin        8.0
#define kLXRefreshViewBottomBorder  4.0


@interface LXRefreshView ()
{
    NSDate          *_lastUpdateTime;
    CGFloat         _scrollViewInitOffsetY;
    UIEdgeInsets    _scrollViewInitInset;
    BOOL            _initEd;
}
@property (assign,nonatomic) LXRefreshStatusType    state;

@property (weak,nonatomic) UILabel                  *timeLabel;
@property (weak,nonatomic) UILabel                  *statusLabel;
@property (weak,nonatomic) UIImageView              *arrowImageView;
@property (weak,nonatomic) UIActivityIndicatorView  *indicator;

@end

@implementation LXRefreshView
#pragma mark - LifeCycle
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        frame.size.height = kLXRefreshViewHeight;
        frame.origin.x = 0.0;
        frame.origin.y = -kLXRefreshViewHeight;
        self.frame = frame;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        _lastUpdateTime = [NSDate date];
        _state = LXRefreshStatusTypeNormal;
        
        [self createMsgBar];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
#pragma mark - refresh
- (void)beginRefresh
{
    if (self.window) {
        self.state = LXRefreshStatusTypeRefreshing;
    }
    else{
        self.state = LXRefreshStatusTypeWillRefresh;
    }

}
- (void)endRefreshWithSuccess:(BOOL)refreshSuccess
{
    if (refreshSuccess) [self updateTime:[NSDate date]];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.state = LXRefreshStatusTypeNormal;
    });
    
    if ([self.delegate respondsToSelector:@selector(refreshViewEndRefresh:)]) {
        [self.delegate refreshViewEndRefresh:self];
    }
}
#pragma mark - layout
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!_initEd) {
        _scrollViewInitOffsetY = _scrollView.contentInset.top;
        _scrollViewInitInset = _scrollView.contentInset;
        
        if (_state == LXRefreshStatusTypeWillRefresh) {
            self.state = LXRefreshStatusTypeRefreshing;
        }
        _initEd = YES;
    }
    
}
#pragma mark - add observer
- (void)setScrollView:(UIScrollView *)scrollView
{
    _scrollView = scrollView;
    [_scrollView addSubview:self];
    
    CGRect frame = self.frame;
    frame.size.width = _scrollView.frame.size.width;
    self.frame = frame;

    [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:Nil];
}
#pragma mark observer state
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    if (![keyPath isEqualToString:@"contentOffset"]) return;
   
    CGFloat offsetY = _scrollView.contentOffset.y * -1;
    if (self.hidden || !self.userInteractionEnabled || !_initEd || !_indicator.hidden) return;

    if (_scrollView.dragging) {
        if(offsetY >= _scrollViewInitOffsetY + kLXRefreshViewHeight)
        {
            self.state = LXRefreshStatusTypePull;
        }
        else{
            self.state = LXRefreshStatusTypeNormal;
        }
    }
    else{
        if (_state == LXRefreshStatusTypePull) {
            self.state = LXRefreshStatusTypeRefreshing;
        }
    }

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
            _scrollView.contentOffset = CGPointMake(0.0, -_scrollViewInitOffsetY);
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
#pragma mark - private
- (void)createMsgBar
{
    UILabel *timeLabel = [self labelWithFont:[UIFont systemFontOfSize:13.0]];
    self.timeLabel = timeLabel;
    [self setupTimeLable];
    CGSize timeLabelSize = [timeLabel.text sizeWithAttributes:@{NSFontAttributeName: timeLabel.font}];
    CGFloat timeLabelX = (self.frame.size.width - timeLabelSize.width)/2.0;
    timeLabel.frame = (CGRect){CGPointMake(timeLabelX,self.frame.size.height - kLXRefreshViewBottomBorder - timeLabelSize.height),timeLabelSize};
    [self addSubview:timeLabel];
    
    
    UILabel *statusLabel = [self labelWithFont:[UIFont systemFontOfSize:13.0]];
    statusLabel.text = LXRefreshMsgNormal;
    CGSize statusLabelSize = [statusLabel.text sizeWithAttributes:@{NSFontAttributeName: statusLabel.font}];
    CGFloat statusLabelX = (self.frame.size.width - statusLabelSize.width)/2.0;
    statusLabel.frame = (CGRect){CGPointMake(statusLabelX, CGRectGetMinY(_timeLabel.frame)-statusLabelSize.height - kLXRefreshViewMargin),statusLabelSize};
    [self addSubview:statusLabel];
    _statusLabel = statusLabel;
    
    UIImage *image = [UIImage imageNamed:@"arrow"];
    UIImageView *arrowImageView = [[UIImageView alloc]init];
    _arrowImageView = arrowImageView;
    [_arrowImageView setImage:image];
    arrowImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    arrowImageView.contentMode = UIViewContentModeCenter;
    CGFloat X = MIN(CGRectGetMinX(statusLabel.frame),CGRectGetMinX(timeLabel.frame));
    arrowImageView.frame = (CGRect){{X-2*kLXRefreshViewMargin-image.size.width,self.frame.size.height - kLXRefreshViewBottomBorder - image.size.height},image.size};
    [self addSubview:arrowImageView];
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self addSubview:indicator];
    indicator.frame = arrowImageView.frame;
    indicator.autoresizingMask = arrowImageView.autoresizingMask;
    _indicator = indicator;
}
- (void)updateTime:(NSDate *)date
{
    NSDateFormatter *fmt = [[NSDateFormatter alloc]init];
    fmt.dateFormat = @"HH:mm";
    NSString *timeStr = [NSString stringWithFormat:@"最近更新:%@",[fmt stringFromDate:date]];
    _timeLabel.text = timeStr;
    
    _lastUpdateTime = date;
}
- (void)setupTimeLable
{
    NSString *timeStr = Nil;
    NSDateFormatter *fmt = [[NSDateFormatter alloc]init];
    fmt.dateFormat = @"HH:mm";
    if ([NSDate isToday:_lastUpdateTime]) {
        timeStr = [NSString stringWithFormat:@"今天 %@",[fmt stringFromDate:_lastUpdateTime]];
    }
    else if([NSDate isYesterday:_lastUpdateTime]){
        timeStr = [NSString stringWithFormat:@"昨天 %@",[fmt stringFromDate:_lastUpdateTime]];
    }
    else{
        fmt.dateFormat = @"yyyy-MM-dd HH:mm";
        timeStr = [NSString stringWithFormat:@"%@",[fmt stringFromDate:_lastUpdateTime]];
    }
    _timeLabel.text = [NSString stringWithFormat:@"最近更新:%@",timeStr];
}
- (UILabel *)labelWithFont:(UIFont *)font
{
    UILabel *label = [[UILabel alloc]init];
    label.font = font;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    return label;
}
- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"contentOffset"];
}
@end
