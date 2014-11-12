//
//
//  Created by xinliu on 14-10-22.
//  Copyright (c) 2014年 xinliu. All rights reserved.
//

#import "LXRefreshFooterView.h"
#import "NSDate+LX.h"

NSString *const LXRefreshFooterViewMsgNormal = @"继续上拉刷新数据";

@interface LXRefreshFooterView ()
{
    CGPoint _scrollViewOldOffset;
    CGFloat _visibleHeight;
    BOOL    _ineted;
}
@end

@implementation LXRefreshFooterView
#pragma mark - LifeCycle
+ (instancetype)footer
{
    return [[self alloc]init];
}
- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.type = LXRefreshViewTypeFooter;
        self.state = LXRefreshStatusTypeNormal;
    }
    return self;
}
- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!_ineted) {
        _ineted = YES;
        
        
        [self.timeLabel removeFromSuperview];
        
        _scrollViewOldOffset = _scrollView.contentOffset;
        _visibleHeight = _scrollView.bounds.size.height - _scrollViewInitInset.top - _scrollViewInitInset.bottom;
        
        CGSize selfSize = self.bounds.size;
        CGSize size = self.statusLabel.bounds.size;
        CGFloat X = (selfSize.width - size.width)/2.0;
        CGFloat Y = (selfSize.height -size.height)/2.0;
        self.statusLabel.frame = CGRectMake(X, Y, size.width, size.height);
        
        CGRect arrF = self.arrowImageView.frame;
        arrF.origin.y = self.bounds.size.height / 2.0;
        self.arrowImageView.center = CGPointMake(arrF.origin.x, self.bounds.size.height / 2.0);
        self.indicator.frame = self.arrowImageView.frame;
    }
}
#pragma mark - add observer
- (void)setScrollView:(UIScrollView *)scrollView
{
    [super setScrollView:scrollView];
    
    [_scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:Nil];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if (![keyPath isEqualToString:@"contentSize"]) return;
    
    CGRect frame = self.frame;
    frame.origin.y = MAX(_scrollView.contentSize.height, _scrollView.bounds.size.height-_scrollViewInitInset.top-_scrollViewInitInset.bottom) ;
    self.frame = frame;
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
            _arrowImageView.transform = CGAffineTransformIdentity;
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
            _scrollView.contentOffset = _scrollViewOldOffset;
        }];
    }
    _statusLabel.text = LXRefreshFooterViewMsgNormal;
    [_indicator stopAnimating];
    _indicator.hidden = YES;
    _arrowImageView.hidden = NO;
    _arrowImageView.transform = CGAffineTransformMakeRotation(-M_PI);
}
- (void)showRefreshState
{
    _statusLabel.text = LXRefreshMsgRefreshing;
    _arrowImageView.hidden = YES;
    _arrowImageView.transform = CGAffineTransformIdentity;
    _indicator.hidden = NO;
    [_indicator startAnimating];
    
    _scrollViewOldOffset = (_scrollView.contentSize.height < _visibleHeight) ? CGPointMake(0.0, -_scrollViewInitOffsetHeight): CGPointMake(0.0, _scrollView.contentSize.height-_visibleHeight-_scrollViewInitOffsetHeight);
    
    UIEdgeInsets inset = _scrollView.contentInset;
    inset = _scrollViewInitInset;
    inset.bottom += self.bounds.size.height;
    _scrollView.contentInset = inset;
    
    _scrollView.contentOffset = CGPointMake(0.0, _scrollView.contentInset.bottom+_scrollView.contentSize.height-_scrollView.bounds.size.height);
    
    if (_scrollView.contentSize.height < _visibleHeight) {
        inset.bottom = _scrollViewInitInset.bottom + _visibleHeight+self.bounds.size.height;
        
        _scrollView.contentInset = inset;
        
        _scrollView.contentOffset = CGPointMake(0.0, -_scrollViewInitInset.top+self.bounds.size.height);
    }
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kLXRefreshRefreshingDur * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([self.delegate respondsToSelector:@selector(refreshViewBeginingRefresh:)]) {
            [self.delegate refreshViewBeginingRefresh:self];
        }
    });
}
- (void)endRefreshWithSuccess:(BOOL)refreshSuccess
{
    if (refreshSuccess && _scrollView.contentSize.height>_scrollView.bounds.size.height+self.bounds.size.height+_scrollViewInitOffsetHeight) {
        CGPoint offset = _scrollViewOldOffset;
        offset.y += self.bounds.size.height;
        _scrollViewOldOffset = offset;
    }
    self.state = LXRefreshStatusTypeNormal;
}

#pragma mark - private
- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"contentSize"];
}
@end
