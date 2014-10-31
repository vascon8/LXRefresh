//
//  LXRefreshView.h
//  0926新浪微博
//
//  Created by xinliu on 14-10-22.
//  Copyright (c) 2014年 xinliu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LXRefreshView;

typedef enum{
    LXRefreshStatusTypeNormal,
    LXRefreshStatusTypeRefreshing,
    LXRefreshStatusTypePull,
    LXRefreshStatusTypeWillRefresh
} LXRefreshStatusType;

extern NSString *const LXRefreshMsgNormal;
extern NSString *const LXRefreshMsgRefreshing;
extern NSString *const LXRefreshMsgRelease;

#define kLXRefreshViewHeight        64.0
#define kLXRefreshBackToNormalDur   0.25

@protocol LXRefreshViewDelegate <NSObject>

- (void)refreshViewBeginingRefresh:(LXRefreshView *)refreshView;
- (void)refreshViewEndRefresh:(LXRefreshView *)refreshView;

@end

@interface LXRefreshView : UIView

@property (weak,nonatomic) UIScrollView *scrollView;
@property (weak,nonatomic) id<LXRefreshViewDelegate>delegate;

- (void)beginRefresh;
- (void)endRefreshWithSuccess:(BOOL)refreshSuccess;

@end
