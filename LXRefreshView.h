//
//
//  Created by xinliu on 14-10-22.
//  Copyright (c) 2014年 xinliu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LXRefreshView;

typedef enum{
    LXRefreshStatusTypeNormal = 1,
    LXRefreshStatusTypeRefreshing,
    LXRefreshStatusTypePull,
    LXRefreshStatusTypeWillRefresh
} LXRefreshStatusType;

typedef enum{
    LXRefreshViewTypeHeader = -1,
    LXRefreshViewTypeFooter = 1
} LXRefreshViewType;

extern NSString *const LXRefreshMsgNormal;
extern NSString *const LXRefreshFooterViewMsgNormal;
extern NSString *const LXRefreshMsgRefreshing;
extern NSString *const LXRefreshMsgRelease;

#define kLXRefreshViewHeight        64.0
#define kLXRefreshFooterViewHeight  49.0
#define kLXRefreshBackToNormalDur   0.25
#define kLXRefreshRefreshingDur     0.3

#define kLXRefreshViewMargin        8.0
#define kLXRefreshViewTopBorder     16.0


@protocol LXRefreshViewDelegate <NSObject>

- (void)refreshViewBeginingRefresh:(LXRefreshView *)refreshView;
- (void)refreshViewEndRefresh:(LXRefreshView *)refreshView;

@end

@interface LXRefreshView : UIView
{
    LXRefreshStatusType              _state;
    __weak UIScrollView              *_scrollView;
    __weak UILabel                   *_timeLabel;
    __weak UILabel                   *_statusLabel;
    __weak UIImageView               *_arrowImageView;
    __weak UIActivityIndicatorView   *_indicator;
    
    CGFloat                          _scrollViewInitOffsetHeight;
    UIEdgeInsets                     _scrollViewInitInset;
}
@property (weak,nonatomic) UIScrollView             *scrollView;
@property (weak,nonatomic) id<LXRefreshViewDelegate>delegate;
@property (assign,nonatomic) LXRefreshViewType      type;

@property (assign,nonatomic) LXRefreshStatusType    state;
@property (weak,nonatomic) UILabel                  *timeLabel;
@property (weak,nonatomic) UILabel                  *statusLabel;
@property (weak,nonatomic) UIImageView              *arrowImageView;
@property (weak,nonatomic) UIActivityIndicatorView  *indicator;

@property (assign,nonatomic) CGFloat                scrollViewInitOffsetHeight;
@property (assign,nonatomic) UIEdgeInsets           scrollViewInitInset;

- (void)beginRefresh;
- (void)endRefreshWithSuccess:(BOOL)refreshSuccess;

@end
