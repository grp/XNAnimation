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

enum {
    XNScrollViewIndicatorStyleDefault,
    XNScrollViewIndicatorStyleBlack,
    XNScrollViewIndicatorStyleWhite
};

typedef NSInteger XNScrollViewIndicatorStyle;

@protocol XNScrollViewDelegate;

@interface XNScrollView : UIView

@property (nonatomic, assign) id<XNScrollViewDelegate> delegate;

@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, assign) CGPoint contentOffset;
- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;
- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated;

@property (nonatomic, assign) CGFloat decelerationRate;
//@property (nonatomic, assign, getter=isDirectionalLockEnabled) BOOL directionalLockEnabled;
//@property (nonatomic, assign, getter=isFastScrollingEnabled) BOOL fastScrollingEnabled;

@property (nonatomic, assign) BOOL bounces;
@property (nonatomic, assign) BOOL alwaysBounceVertical;
@property (nonatomic, assign) BOOL alwaysBounceHorizontal;

@property (nonatomic) BOOL showsHorizontalScrollIndicator;
@property (nonatomic) BOOL showsVerticalScrollIndicator;
@property (nonatomic) UIEdgeInsets scrollIndicatorInsets;
@property (nonatomic) XNScrollViewIndicatorStyle indicatorStyle;
- (void)flashScrollIndicators;

//@property (nonatomic, assign, getter=isPagingEnabled) BOOL pagingEnabled;

@property (nonatomic, getter=isScrollEnabled) BOOL scrollEnabled;
- (void)stopScrolling;

@property (nonatomic, assign, readonly, getter=isDecelerating) BOOL decelerating; // decelerating from touch
//@property(nonatomic, assign, readonly, getter=isTracking) BOOL tracking;
@property (nonatomic, assign, readonly, getter=isDragging) BOOL dragging; // touching with finger
@property (nonatomic, assign, readonly, getter=isScrolling) BOOL scrolling; // not programmatic

@property (nonatomic, retain, readonly) UIPanGestureRecognizer *panGestureRecognizer;
//@property (nonatomic, assign) BOOL delaysContentTouches;
//@property (nonatomic, assign) BOOL canCancelContentTouches;

//- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view;
//- (BOOL)touchesShouldCancelInContentView:(UIView *)view;

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
