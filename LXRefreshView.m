//
//
//  Created by xinliu on 14-10-22.
//  Copyright (c) 2014年 xinliu. All rights reserved.
//

#import "LXRefreshView.h"
#import "NSDate+LX.h"

NSString *const LXRefreshMsgRefreshing = @"正在刷新数据......";
NSString *const LXRefreshMsgRelease = @"松开立即刷新";

@interface LXRefreshView ()
{
    BOOL            _initEd;
    CGFloat         _deltaHeight;
    CGFloat         _visibleHeight;
}
@end

@implementation LXRefreshView
#pragma mark - LifeCycle
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        frame.size.height = kLXRefreshViewHeight;
        frame.origin.x = 0.0;
        self.frame = frame;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
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

}
#pragma mark - layout
- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!_initEd) {
        
        if (self.type == LXRefreshViewTypeFooter) {
            CGRect selfF = self.frame;
            selfF.size.height = kLXRefreshFooterViewHeight;
            self.frame = selfF;
        }
        
        _scrollViewInitOffsetHeight = -_scrollView.contentOffset.y;
        _scrollViewInitInset = _scrollView.contentInset;
        _deltaHeight = self.bounds.size.height;
        _visibleHeight = _scrollView.bounds.size.height - _scrollViewInitInset.top - _scrollViewInitInset.bottom;
        
        CGRect scrollFrame = _scrollView.frame;
        
        CGFloat headerY = - self.bounds.size.height;
        CGFloat footerY = MAX(_scrollView.contentSize.height, _visibleHeight);
        CGFloat Y = (self.type == LXRefreshViewTypeHeader) ? headerY : footerY;
        CGRect frame = self.frame;
        frame.origin.y = Y;
        frame.size.width = scrollFrame.size.width;
        self.frame = frame;
        
        [self adjustMsgBarPosition];
        
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
    
    [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:Nil];
}
#pragma mark observer state
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (![keyPath isEqualToString:@"contentOffset"]) return;
   
    CGFloat offsetHeight = (_scrollView.contentOffset.y + _scrollViewInitOffsetHeight)*self.type;

    if (self.hidden || !self.userInteractionEnabled || !_initEd || !_indicator.hidden) return;
    
    if (_scrollView.dragging) {
        
        if (self.type == LXRefreshViewTypeFooter)
        {
            _deltaHeight = _scrollView.contentSize.height+self.bounds.size.height;
            
            offsetHeight += _visibleHeight;
            
            if (_scrollView.contentSize.height < _visibleHeight) {
                _deltaHeight = (self.frame.origin.y+self.bounds.size.height);
            }
        }
        
        if(offsetHeight >= _deltaHeight)
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
#pragma mark - private
- (void)createMsgBar
{
    UILabel *statusLabel = [self labelWithFont:[UIFont systemFontOfSize:13.0]];
    [self addSubview:statusLabel];
    _statusLabel = statusLabel;
    
    UILabel *timeLabel = [self labelWithFont:[UIFont systemFontOfSize:13.0]];
    self.timeLabel = timeLabel;
    [self addSubview:timeLabel];
    
    UIImage *image = [UIImage imageNamed:@"LXRefresh.bundle/arrow"];
    UIImageView *arrowImageView = [[UIImageView alloc]init];
    _arrowImageView = arrowImageView;
    [_arrowImageView setImage:image];
    arrowImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    arrowImageView.contentMode = UIViewContentModeCenter;
    [self addSubview:arrowImageView];
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self addSubview:indicator];
    indicator.autoresizingMask = arrowImageView.autoresizingMask;
    _indicator = indicator;
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

- (void)adjustMsgBarPosition
{
    CGFloat selfW = self.frame.size.width;
    
    CGSize statusLabelSize = [_statusLabel.text sizeWithAttributes:@{NSFontAttributeName: _statusLabel.font}];
    CGFloat statusLabelX = (selfW - statusLabelSize.width)/2.0;
    CGFloat statusLabelY = kLXRefreshViewTopBorder;
    _statusLabel.frame = (CGRect){CGPointMake(statusLabelX,statusLabelY),statusLabelSize};
    
    CGSize timeLabelSize = [self.timeLabel.text sizeWithAttributes:@{NSFontAttributeName : self.timeLabel.font}];
    CGFloat timeLabelX = (selfW - timeLabelSize.width)/2.0;
    self.timeLabel.frame = (CGRect){CGPointMake(timeLabelX,CGRectGetMaxY(self.statusLabel.frame)+kLXRefreshViewMargin),timeLabelSize};
    
    CGSize imgSize = _arrowImageView.image.size;
    CGFloat X = MIN(CGRectGetMinX(_statusLabel.frame),CGRectGetMinX(_timeLabel.frame));
    _arrowImageView.frame = (CGRect){{X-2*kLXRefreshViewMargin-imgSize.width,kLXRefreshViewTopBorder},imgSize};
    
    _indicator.frame = _arrowImageView.frame;
}
- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"contentOffset"];
}

@end
