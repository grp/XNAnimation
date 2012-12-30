//
//  XNScrollView.h
//  Animations
//
//  Created by Grant Paul on 12/30/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "NSObject+XNAnimation.h"

#import <UIKit/UIScrollView.h>

extern const CGFloat XNScrollViewDecelerationRateNormal;
extern const CGFloat XNScrollViewDecelerationRateFast;

@protocol XNScrollViewDelegate;

@interface XNScrollView : UIView

@property (nonatomic, assign) id<XNScrollViewDelegate> delegate;

@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, assign) CGPoint contentOffset;
- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;

@property (nonatomic, assign) CGFloat decelerationRate;
//@property (nonatomic, assign, getter=isDirectionalLockEnabled) BOOL directionalLockEnabled;
//@property (nonatomic, assign, getter=isFastScrollingEnabled) BOOL fastScrollingEnabled;

@property (nonatomic, assign) BOOL bounces;
@property (nonatomic, assign) BOOL alwaysBounceVertical;
@property (nonatomic, assign) BOOL alwaysBounceHorizontal;

//@property (nonatomic) BOOL showsHorizontalScrollIndicator;
//@property (nonatomic) BOOL showsVerticalScrollIndicator;
//@property (nonatomic) UIEdgeInsets scrollIndicatorInsets;
//@property (nonatomic) UIScrollViewIndicatorStyle indicatorStyle;

//@property (nonatomic, assign, getter=isPagingEnabled) BOOL pagingEnabled;

@property (nonatomic, getter=isScrollEnabled) BOOL scrollEnabled;
- (void)stopScrolling;

@property (nonatomic, readonly, getter=isDecelerating) BOOL decelerating; // decelerating from touch
@property (nonatomic, readonly, getter=isDragging) BOOL dragging; // touching with finger
@property (nonatomic, readonly, getter=isScrolling) BOOL scrolling; // not programmatic

@property (nonatomic, readonly) UIPanGestureRecognizer *panGestureRecognizer;

@end

@protocol XNScrollViewDelegate <NSObject>
@optional

- (void)scrollViewWillBeginScrolling:(XNScrollView *)scrollView; // not programmatic
- (void)scrollViewDidScroll:(XNScrollView *)scrollView;
- (void)scrollViewDidEndScrolling:(XNScrollView *)scrollView; // not programmatic

- (void)scrollViewWillBeginDragging:(XNScrollView *)scrollView;
//- (void)scrollViewWillEndDragging:(XNScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset;
- (void)scrollViewDidEndDragging:(XNScrollView *)scrollView willDecelerate:(BOOL)decelerate;

- (void)scrollViewWillBeginDecelerating:(XNScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(XNScrollView *)scrollView;

- (void)scrollViewDidEndScrollingAnimation:(XNScrollView *)scrollView; // programmatic scroll only

//- (BOOL)scrollViewShouldScrollToTop:(XNScrollView *)scrollView;
//- (void)scrollViewDidScrollToTop:(XNScrollView *)scrollView;

@end
