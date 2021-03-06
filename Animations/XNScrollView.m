//
//  XNScrollView.m
//  Animations
//
//  Created by Grant Paul on 12/30/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

#import "XNScrollView.h"

// iOS 6 introduces a new formula for this, depending on the dimensions of the
// scroll view as well as a constant. This option can either emulate that new
// behavior or the previous simple scaling by the defined elastic constant.
const static BOOL kXNScrollViewElasticSimpleFormula = (__IPHONE_OS_VERSION_MAX_ALLOWED < 60000);
const static CGFloat kXNScrollViewElasticConstant = 0.55f;

const static CGFloat kXNScrollViewDecelerationMinimumVelocity = 250.0f;
const static CGFloat kXNScrollViewDecelerationCurrentVelocityFactor = 0.25f;

const CGFloat XNScrollViewDecelerationRateNormal = 0.998f;
const CGFloat XNScrollViewDecelerationRateFast = 0.990f;

const static CGFloat kXNScrollViewIndicatorMinimumDimension = 9.0f;
const static CGFloat kXNScrollViewIndicatorMinimumLongDimension = kXNScrollViewIndicatorMinimumDimension;
const static CGFloat kXNScrollViewIndicatorMinimumLongDimensionDefault = 12.0f;
const static CGFloat kXNScrollViewIndicatorMinimumInsideLength = 36.0f;
const static CGFloat kXNScrollViewIndicatorCornerDimension = 6.0f;
const static NSTimeInterval kXNScrollViewIndicatorAnimationDuration = 0.25f;
const static NSTimeInterval kXNScrollViewIndicatorFlashingDuration = 0.75f;

@interface XNScrollViewIndicator : UIView

@property (nonatomic, assign) XNScrollViewIndicatorStyle indicatorStyle;

@end

@implementation XNScrollViewIndicator {
    XNScrollViewIndicatorStyle _indicatorStyle;
}

@synthesize indicatorStyle = _indicatorStyle;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setOpaque:NO];
    }

    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];

    [self setNeedsDisplay];
}

- (void)setIndicatorStyle:(XNScrollViewIndicatorStyle)indicatorStyle {
    _indicatorStyle = indicatorStyle;

    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    UIColor *lightColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
    UIColor *lightBorderColor = [UIColor colorWithWhite:1.0f alpha:0.3f];
    UIColor *darkColor = [UIColor colorWithWhite:0.0f alpha:0.5f];

    CGRect barRect = CGRectInset(rect, 1.0f, 1.0f);
    CGFloat barShortLength = fminf(barRect.size.width, barRect.size.height);

    CGRect insideRect = CGRectInset(barRect, 1.0f, 1.0f);
    
    if ([self indicatorStyle] == XNScrollViewIndicatorStyleDefault) {
        [darkColor setFill];
    } else if ([self indicatorStyle] == XNScrollViewIndicatorStyleWhite) {
        [lightColor setFill];
    } else {
        [darkColor setFill];
    }
    
    CGFloat insideShortLength = fminf(insideRect.size.width, insideRect.size.height);
    UIBezierPath *innerPath = [UIBezierPath bezierPathWithRoundedRect:insideRect cornerRadius:(insideShortLength / 2.0f)];
    [innerPath fill];

    if ([self indicatorStyle] == XNScrollViewIndicatorStyleDefault) {
        [lightBorderColor setFill];

        UIBezierPath *outerPath = [UIBezierPath bezierPathWithRoundedRect:barRect cornerRadius:(barShortLength / 2.0f)];
        [outerPath appendPath:innerPath];
        [outerPath setUsesEvenOddFillRule:YES];
        [outerPath fill];
    }
}

@end

@interface XNScrollViewPanGestureRecognizer : UIPanGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action scrollView:(XNScrollView *)scrollView;
@property (nonatomic, assign, readonly) XNScrollView *scrollView;

@property (nonatomic, assign, readonly, getter=isTracking) BOOL tracking;

@end

@implementation XNScrollViewPanGestureRecognizer {
    XNScrollView *_scrollView;
    BOOL _tracking;
}

@synthesize scrollView = _scrollView;
@synthesize tracking = _tracking;

- (id)initWithTarget:(id)target action:(SEL)action scrollView:(XNScrollView *)scrollView {
    if ((self = [super initWithTarget:target action:action])) {
        _scrollView = scrollView;
        _tracking = NO;
    }

    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([_scrollView isDecelerating]) {
        [self setState:UIGestureRecognizerStateBegan];
    }

    _tracking = YES;

    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];

    if ([self state] == UIGestureRecognizerStateBegan) {
        BOOL cancel = [_scrollView canCancelContentTouches];

        if (cancel) {
            NSSet *touches = [event touchesForGestureRecognizer:self];

            for (UITouch *touch in touches) {
                UIView *view = [touch view];

                if (view != _scrollView && ![_scrollView touchesShouldCancelInContentView:view]) {
                    cancel = NO;
                    break;
                }
            }
        }

        if (!cancel) {
            [self setState:UIGestureRecognizerStateFailed];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    _tracking = NO;

    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    _tracking = NO;

    [super touchesCancelled:touches withEvent:event];
}

@end

@interface XNScrollView () <XNAnimationDelegate>
@end

@implementation XNScrollView {
    CGSize _contentSize;
    CGPoint _contentOffset;
    XNAnimation *_offsetAnimation;

    CGFloat _decelerationRate;

    CGPoint _throwTranslation;
    CGPoint _throwVelocity;

  CGPoint _previousVelocity;
  CGPoint _previousPreviousVelocity;

    XNScrollViewPanGestureRecognizer *_panGestureRecognizer;
    CGPoint _panStartContentOffset;
    XNAnimation *_scrollAnimation;

    UIEdgeInsets _scrollIndicatorInsets;
    XNScrollViewIndicatorStyle _indicatorStyle;
    XNScrollViewIndicator *_horizontalScrollIndicator;
    XNScrollViewIndicator *_verticalScrollIndicator;
    XNAnimation *_horizontalScrollIndicatorAnimation;
    XNAnimation *_verticalScrollIndicatorAnimation;

    struct {
        BOOL __scrollEnabled:1;
#define _scrollEnabled _flags.__scrollEnabled

        BOOL __showsHorizontalScrollIndicator:1;
#define _showsHorizontalScrollIndicator _flags.__showsHorizontalScrollIndicator
        BOOL __showsVerticalScrollIndicator:1;
#define _showsVerticalScrollIndicator _flags.__showsVerticalScrollIndicator
        BOOL __horizontalScrollIndicatorVisible:1;
#define _horizontalScrollIndicatorVisible _flags.__horizontalScrollIndicatorVisible
        BOOL __verticalScrollIndicatorVisible:1;
#define _verticalScrollIndicatorVisible _flags.__verticalScrollIndicatorVisible

        BOOL __bounces:1;
#define _bounces _flags.__bounces
        BOOL __alwaysBounceHorizontal:1;
#define _alwaysBounceHorizontal _flags.__alwaysBounceHorizontal
        BOOL __alwaysBounceVertical:1;
#define _alwaysBounceVertical _flags.__alwaysBounceVertical

        BOOL __dragging:1;
#define _dragging _flags.__dragging
        BOOL __decelerating:1;
#define _decelerating _flags.__decelerating
        BOOL __scrolling:1;
#define _scrolling _flags.__scrolling

        BOOL __canCancelContentTouches:1;
#define _canCancelContentTouches _flags.__canCancelContentTouches
    } _flags;

    id<XNScrollViewDelegate> _delegate;
    struct {
        BOOL _scrollViewWillBeginScrolling:1;
        BOOL _scrollViewDidScroll:1;
        BOOL _scrollViewDidEndScrolling:1;
        BOOL _scrollViewWillBeginDragging:1;
        //BOOL _scrollViewWillEndDraggingWithVelocityTargetContentOffset:1;
        BOOL _scrollViewDidEndDraggingWillDecelerate:1;
        BOOL _scrollViewWillBeginDecelerating:1;
        BOOL _scrollViewDidEndDecelerating:1;
        BOOL _scrollViewDidEndScrollingAnimation:1;
        //BOOL _scrollViewShouldScrollToTop:1;
        //BOOL _scrollViewDidScrollToTop:1;
    } _delegateFlags;
}

#pragma mark - Delegation Private Methods

- (void)_delegateWillBeginScrolling {
    if (_delegateFlags._scrollViewWillBeginScrolling) {
        [_delegate scrollViewWillBeginScrolling:self];
    }
}

- (void)_delegateDidScroll {
    if (_delegateFlags._scrollViewDidScroll) {
        [_delegate scrollViewDidScroll:self];
    }
}

- (void)_delegateDidEndScrolling {
    if (_delegateFlags._scrollViewDidEndScrolling) {
        [_delegate scrollViewDidEndScrolling:self];
    }
}

- (void)_delegateWillBeginDragging {
    if (_delegateFlags._scrollViewWillBeginDragging) {
        [_delegate scrollViewWillBeginDragging:self];
    }
}

//- (void)_delegateWillEndDraggingWithVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
//    if (_delegateFlags._scrollViewWillEndDraggingWithVelocityTargetContentOffset) {
//        [_delegate scrollViewDidEndDragging:self withVelocity:velocity targetContentOffset:targetContentOffset];
//    }
//}

- (void)_delegateDidEndDraggingWillDecelerate:(BOOL)decelerate {
    if (_delegateFlags._scrollViewDidEndDraggingWillDecelerate) {
        [_delegate scrollViewDidEndDragging:self willDecelerate:decelerate];
    }
}

- (void)_delegateWillBeginDecelerating {
    if (_delegateFlags._scrollViewWillBeginDecelerating) {
        [_delegate scrollViewWillBeginDecelerating:self];
    }
}

- (void)_delegateDidEndDecelerating {
    if (_delegateFlags._scrollViewDidEndDecelerating) {
        [_delegate scrollViewDidEndDecelerating:self];
    }
}

- (void)_delegateDidEndScrollingAnimation {
    if (_delegateFlags._scrollViewDidEndScrollingAnimation) {
        [_delegate scrollViewDidEndScrollingAnimation:self];
    }
}

//- (BOOL)_delegateShouldScrollToTop {
//    if (_delegateFlags._scrollViewShouldScrollToTop) {
//        return [_delegate scrollViewShouldScrollToTop:self];
//    }
//}

//- (void)_delegateDidScrollToTop {
//    if (_delegateFlags._scrollViewDidScrollToTop) {
//        [_delegate scrollViewDidScrollToTop:self];
//    }
//}

#pragma mark - Properties

@synthesize delegate = _delegate;
@synthesize contentSize = _contentSize;
@synthesize contentInset = _contentInset;
@synthesize panGestureRecognizer = _panGestureRecognizer;
@synthesize decelerationRate = _decelerationRate;
@synthesize indicatorStyle = _indicatorStyle;
@synthesize scrollIndicatorInsets = _scrollIndicatorInsets;

- (void)setDelegate:(id<XNScrollViewDelegate>)delegate {
    _delegate = delegate;

    _delegateFlags._scrollViewWillBeginScrolling = [_delegate respondsToSelector:@selector(scrollViewWillBeginScrolling:)];
    _delegateFlags._scrollViewDidScroll = [_delegate respondsToSelector:@selector(scrollViewDidScroll:)];
    _delegateFlags._scrollViewDidEndScrolling = [_delegate respondsToSelector:@selector(scrollViewDidEndScrolling:)];
    _delegateFlags._scrollViewWillBeginDragging = [_delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)];
    //_delegateFlags._scrollViewWillEndDraggingWithVelocityTargetContentOffset = [_delegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)];
    _delegateFlags._scrollViewDidEndDraggingWillDecelerate = [_delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)];
    _delegateFlags._scrollViewWillBeginDecelerating = [_delegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)];
    _delegateFlags._scrollViewDidEndDecelerating = [_delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)];
    _delegateFlags._scrollViewDidEndScrollingAnimation = [_delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)];
    //_delegateFlags._scrollViewShouldScrollToTop = [_delegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)];
    //_delegateFlags._scrollViewDidScrollToTop = [_delegate respondsToSelector:@selector(scrollViewDidScrollToTop:)];
}

- (void)didAddSubview:(UIView *)subview {
    [super didAddSubview:subview];

    [self bringSubviewToFront:_horizontalScrollIndicator];
    [self bringSubviewToFront:_verticalScrollIndicator];
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
    _contentInset = contentInset;

    [self _updateForGeometryChange];
}

- (void)setContentSize:(CGSize)contentSize {
    _contentSize = contentSize;

    [self _updateForGeometryChange];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];

    [self _updateForGeometryChange];
}

- (CGPoint)contentOffset {
    return [self bounds].origin;
}

- (void)setContentOffset:(CGPoint)contentOffset {
    CGRect bounds = [self bounds];
    bounds.origin = contentOffset;
    [self setBounds:bounds];

    [self _layoutScrollIndicators];

    [self _delegateDidScroll];
}

- (void)setDecelerationRate:(CGFloat)decelerationRate {
    _decelerationRate = decelerationRate;

    XNDecayTimingFunction *timingFunction = (XNDecayTimingFunction *) [_scrollAnimation timingFunction];
    [timingFunction setConstant:decelerationRate];
}

- (void)setShowsHorizontalScrollIndicator:(BOOL)showsHorizontalScrollIndicator {
    _showsHorizontalScrollIndicator = showsHorizontalScrollIndicator;
}

- (BOOL)showsHorizontalScrollIndicator {
    return _showsHorizontalScrollIndicator;
}

- (void)setShowsVerticalScrollIndicator:(BOOL)showsVerticalScrollIndicator {
    _showsVerticalScrollIndicator = showsVerticalScrollIndicator;
}

- (BOOL)showsVerticalScrollIndicator {
    return _showsVerticalScrollIndicator;
}

- (void)setIndicatorStyle:(XNScrollViewIndicatorStyle)indicatorStyle {
    _indicatorStyle = indicatorStyle;
}

- (void)setScrollIndicatorInsets:(UIEdgeInsets)scrollIndicatorInsets {
    _scrollIndicatorInsets = scrollIndicatorInsets;
}

- (BOOL)bounces {
    return _bounces;
}

- (void)setBounces:(BOOL)bounces {
    _bounces = bounces;

    [self _updateForGeometryChange];
}

- (BOOL)alwaysBounceHorizontal {
    return _alwaysBounceHorizontal;
}

- (void)setAlwaysBounceHorizontal:(BOOL)alwaysBounceHorizontal {
    _alwaysBounceHorizontal = alwaysBounceHorizontal;

    [self _updateForGeometryChange];
}

- (BOOL)alwaysBounceVertical {
    return _alwaysBounceVertical;
}

- (void)setAlwaysBounceVertical:(BOOL)alwaysBounceVertical {
    _alwaysBounceVertical = alwaysBounceVertical;

    [self _updateForGeometryChange];
}

- (BOOL)isDecelerating {
    return _decelerating;
}

- (BOOL)isDragging {
    return _dragging;
}

- (BOOL)isScrolling {
    return _scrolling;
}

- (BOOL)isTracking {
    XNScrollViewPanGestureRecognizer *panGestureRecognizer = (XNScrollViewPanGestureRecognizer *) [self panGestureRecognizer];
    return [panGestureRecognizer isTracking];
}

- (BOOL)isScrollEnabled {
    return _scrollEnabled;
}

- (void)setScrollEnabled:(BOOL)scrollEnabled {
    _scrollEnabled = scrollEnabled;

    if (![self isScrollEnabled] && [self isScrolling]) {
        [self stopScrolling];
    }

    UIPanGestureRecognizer *panGestureRecognizer = [self panGestureRecognizer];
    [panGestureRecognizer setEnabled:scrollEnabled];
}

- (BOOL)canCancelContentTouches {
    return _canCancelContentTouches;
}

- (void)setCanCancelContentTouches:(BOOL)canCancelContentTouches {
    _canCancelContentTouches = canCancelContentTouches;
}

#pragma mark - Methods

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    if (animated) {
        [self stopScrolling];

        NSValue *fromValue = [NSValue valueWithCGPoint:[self contentOffset]];
        NSValue *toValue = [NSValue valueWithCGPoint:contentOffset];
        NSValue *velocityValue = [NSValue valueWithCGPoint:CGPointZero];

        [_offsetAnimation setFromValue:fromValue];
        [_offsetAnimation setToValue:toValue];
        [_offsetAnimation setVelocity:velocityValue];

        [self addXNAnimation:_offsetAnimation];
    } else {
        [self setContentOffset:contentOffset];
    }
}

- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated {
    CGPoint topLeft = rect.origin;
    CGPoint bottomRight = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));

    CGPoint contentOffset = [self contentOffset];
    CGRect bounds = [self bounds];
    CGRect visibleRect = { contentOffset, bounds.size };

    if (CGRectContainsPoint(visibleRect, topLeft) && CGRectContainsPoint(visibleRect, bottomRight)) {
        return;
    }

    CGPoint visibleTopLeft = contentOffset;
    CGPoint visibleBottomRight = CGPointMake(contentOffset.x + bounds.size.width, contentOffset.y + bounds.size.height);

    if (topLeft.x < visibleTopLeft.x) {
        contentOffset.x = topLeft.x;
    } else if (bottomRight.x > visibleBottomRight.x) {
        contentOffset.x += (bottomRight.x - visibleBottomRight.x);
    }

    if (topLeft.y < visibleTopLeft.y) {
        contentOffset.y = topLeft.y;
    } else if (bottomRight.y > visibleBottomRight.y) {
        contentOffset.y += (bottomRight.y - visibleBottomRight.y);
    }

    [self setContentOffset:contentOffset animated:animated];
}

- (void)stopScrolling {
    if (_dragging && [_panGestureRecognizer state] != UIGestureRecognizerStateBegan) {
        [_panGestureRecognizer setEnabled:NO];
        [_panGestureRecognizer setEnabled:YES];
    }
    
    [self removeXNAnimation:_scrollAnimation];
    [self removeXNAnimation:_offsetAnimation];
}

- (void)removeFromSuperview {
    [self stopScrolling];
    [super removeFromSuperview];
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    if ([view isKindOfClass:[UIControl class]]) {
        UIControl *control = (UIControl *) view;

        if ([control isEnabled]) {
            return NO;
        }
    }

    return YES;
}

- (void)flashScrollIndicators {
    [self _cancelScrollIndicatorFlash];
    [self _updateIndicatorsVisible:YES animated:YES];

    NSTimeInterval duration = (kXNScrollViewIndicatorAnimationDuration + kXNScrollViewIndicatorFlashingDuration);
    [self performSelector:@selector(_hideScrollIndicatorsAfterFlash) withObject:nil afterDelay:duration];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _scrollEnabled = YES;
        _bounces = YES;

        _indicatorStyle = XNScrollViewIndicatorStyleDefault;
        _showsHorizontalScrollIndicator = YES;
        _showsVerticalScrollIndicator = YES;
        _scrollIndicatorInsets = UIEdgeInsetsZero;
        
        _horizontalScrollIndicator = [[XNScrollViewIndicator alloc] init];
        _verticalScrollIndicator = [[XNScrollViewIndicator alloc] init];
        _horizontalScrollIndicatorVisible = NO;
        _verticalScrollIndicatorVisible = NO;

        XNBezierTimingFunction *indicatorTimingFunction = [XNBezierTimingFunction timingFunctionWithControlPoints:[XNBezierTimingFunction controlPointsEaseInOut]];
        _horizontalScrollIndicatorAnimation = [[XNAnimation alloc] initWithKeyPath:@"alpha"];
        [_horizontalScrollIndicatorAnimation setTimingFunction:indicatorTimingFunction];
        [_horizontalScrollIndicatorAnimation setDelegate:self];
        _verticalScrollIndicatorAnimation = [[XNAnimation alloc] initWithKeyPath:@"alpha"];
        [_verticalScrollIndicatorAnimation setTimingFunction:indicatorTimingFunction];
        [_verticalScrollIndicatorAnimation setDelegate:self];

        _panGestureRecognizer = [[XNScrollViewPanGestureRecognizer alloc] initWithTarget:self action:@selector(_panFromGestureRecognizer:) scrollView:self];
        [_panGestureRecognizer setMaximumNumberOfTouches:(kXNScrollViewElasticSimpleFormula ? 1 : INT_MAX)];
        [_panGestureRecognizer setDelaysTouchesEnded:NO];
        [self addGestureRecognizer:_panGestureRecognizer];

        _canCancelContentTouches = YES;
        
        _scrollAnimation = [[XNAnimation alloc] initWithKeyPath:@"contentOffset"];
        [_scrollAnimation setTimingFunction:[XNDecayTimingFunction timingFunction]];
        [self setDecelerationRate:XNScrollViewDecelerationRateNormal];
        [_scrollAnimation setDelegate:self];

        _offsetAnimation = [[XNAnimation alloc] initWithKeyPath:@"contentOffset"];
        [_offsetAnimation setTimingFunction:[XNSpringTimingFunction timingFunctionWithTension:100.0f damping:20.0f mass:1.0f]];
        [_offsetAnimation setDelegate:self];
    }

    return self;
}

- (void)dealloc {
    [self stopScrolling];

    [_horizontalScrollIndicator release];
    [_verticalScrollIndicator release];
    [_horizontalScrollIndicatorAnimation release];
    [_verticalScrollIndicatorAnimation release];

    [_panGestureRecognizer release];
    [_scrollAnimation release];

    [_offsetAnimation release];

    [super dealloc];
}

#pragma mark - Computed State


- (CGRect)_effectiveScrollBounds {
    CGRect bounds = [self bounds];
    CGSize contentSize = [self contentSize];
    UIEdgeInsets contentInset = [self contentInset];

    if (contentSize.width < bounds.size.width) {
        contentSize.width = bounds.size.width;
    } else if (contentSize.height < bounds.size.height) {
        contentSize.height = bounds.size.height;
    }

    CGRect scrollBounds = CGRectZero;
    scrollBounds.origin.x = 0;
    scrollBounds.origin.y = 0;
    scrollBounds.size.width = contentSize.width - bounds.size.width;
    scrollBounds.size.height = contentSize.height - bounds.size.height;

    UIEdgeInsets invertedInsets = UIEdgeInsetsMake(-contentInset.top, -contentInset.left, -contentInset.bottom, -contentInset.right);
    scrollBounds = UIEdgeInsetsInsetRect(scrollBounds, invertedInsets);

    return scrollBounds;
}

- (BOOL)_effectiveScrollsHorizontally {
    CGRect scrollBounds = [self _effectiveScrollBounds];
    return (scrollBounds.size.width > 0);
}

- (BOOL)_effectiveScrollsVertically {
    CGRect scrollBounds = [self _effectiveScrollBounds];
    return (scrollBounds.size.height > 0);
}

- (BOOL)_effectiveBouncesHorizontally {
    return [self bounces] && ([self alwaysBounceHorizontal] || [self _effectiveScrollsHorizontally]);
}

- (BOOL)_effectiveBouncesVertically {
    return [self bounces] && ([self alwaysBounceVertical] || [self _effectiveScrollsVertically]);
}

- (BOOL)_effectiveShowsHorizontalScrollIndicator {
    return [self showsHorizontalScrollIndicator] && [self _effectiveScrollsHorizontally];
}

- (BOOL)_effectiveShowsVerticalScrollIndicator {
    return [self showsVerticalScrollIndicator] && [self _effectiveScrollsVertically];
}

#pragma mark - Graphical Computation

- (CGFloat)_elasticDistanceForDistance:(CGFloat)distance constant:(CGFloat)constant range:(CGFloat)range {
    if (kXNScrollViewElasticSimpleFormula) {
        distance = distance * constant;
    } else {
        distance = (distance * constant * range) / (distance * constant + range);
    }
    
    return distance;
}

- (CGPoint)_constrainContentOffset:(CGPoint)offset toScrollBounds:(CGRect)scrollBounds elastic:(BOOL)elastic {
    CGFloat elasticConstant = (elastic ? kXNScrollViewElasticConstant : 0.0f);
    CGFloat horizontalConstant = ([self _effectiveBouncesHorizontally] ? elasticConstant : 0.0f);
    CGFloat verticalConstant = ([self _effectiveBouncesVertically] ? elasticConstant : 0.0f);

    if (offset.x < CGRectGetMinX(scrollBounds)) {
        CGFloat range = [self bounds].size.width;
        CGFloat edge = CGRectGetMinX(scrollBounds);
        
        CGFloat distance = fabsf(offset.x - edge);
        distance = [self _elasticDistanceForDistance:distance constant:horizontalConstant range:range];
        
        offset.x = edge - distance;
    } else if (offset.x > CGRectGetMaxX(scrollBounds)) {
        CGFloat range = [self bounds].size.width;
        CGFloat edge = CGRectGetMaxX(scrollBounds);

        CGFloat distance = fabsf(offset.x - edge);
        distance = [self _elasticDistanceForDistance:distance constant:horizontalConstant range:range];

        offset.x = edge + distance;
    }

    if (offset.y < CGRectGetMinY(scrollBounds)) {
        CGFloat range = [self bounds].size.height;
        CGFloat edge = CGRectGetMinY(scrollBounds);

        CGFloat distance = fabsf(offset.y - edge);
        distance = [self _elasticDistanceForDistance:distance constant:verticalConstant range:range];

        offset.y = edge - distance;
    } else if (offset.y > CGRectGetMaxY(scrollBounds)) {
        CGFloat range = [self bounds].size.height;
        CGFloat edge = CGRectGetMaxY(scrollBounds);

        CGFloat distance = fabsf(offset.y - edge);
        distance = [self _elasticDistanceForDistance:distance constant:verticalConstant range:range];

        offset.y = edge + distance;
    }

    return offset;
}

- (CGFloat)_lengthForIndicatorWithDimension:(CGFloat)dimension contentDimension:(CGFloat)contentDimension position:(CGFloat)position {
    CGFloat outside = 0;
    CGFloat minimum = kXNScrollViewIndicatorMinimumInsideLength;


    if (position < 0) {
        outside = fabsf(position);

        minimum = kXNScrollViewIndicatorMinimumDimension;
        if (_indicatorStyle == XNScrollViewIndicatorStyleDefault) {
          minimum = kXNScrollViewIndicatorMinimumLongDimension;
        }
    } else if (position > contentDimension) {
        outside = fabsf(position - contentDimension);
      
        minimum = kXNScrollViewIndicatorMinimumDimension;
        if (_indicatorStyle == XNScrollViewIndicatorStyleDefault) {
          minimum = kXNScrollViewIndicatorMinimumLongDimension;
        }
    }

    CGFloat partialDisplayed = (dimension / (contentDimension + dimension));
    CGFloat length = dimension * partialDisplayed;
    
    length = fmaxf(length, kXNScrollViewIndicatorMinimumInsideLength);
    length = length - outside;
    length = fmaxf(length, minimum);
    
    return length;
}

- (CGFloat)_positionForIndicatorWithDimension:(CGFloat)dimension contentDimension:(CGFloat)contentDimension position:(CGFloat)position {
    CGFloat length = [self _lengthForIndicatorWithDimension:dimension contentDimension:contentDimension position:position];

    CGFloat partialPosition = (position / contentDimension);
    CGFloat pos = (dimension - length) * partialPosition;
    
    if (pos + length > dimension) {
        pos = dimension - length;
    } else if (position < 0) {
        pos = 0;
    }
    
    return pos;
}

#pragma mark - Animation Delegate

- (void)animationStopped:(XNAnimation *)animation {
    if (animation == _scrollAnimation) {
        _decelerating = NO;
        _scrolling = NO;
        [self _delegateDidEndDecelerating];
        [self _delegateDidEndScrolling];

        [self _updateIndicatorsVisible:NO animated:[animation completed]];
    } else if (animation == _offsetAnimation) {
        [self _delegateDidEndScrollingAnimation];
    } else if (animation == _horizontalScrollIndicatorAnimation || animation == _verticalScrollIndicatorAnimation) {
        XNScrollViewIndicator *indicator = nil;
        BOOL visible = NO;
        
        if (animation == _horizontalScrollIndicatorAnimation) {
            indicator = _horizontalScrollIndicator;
            visible = _horizontalScrollIndicatorVisible;
        } else if (animation == _verticalScrollIndicatorAnimation) {
            indicator = _verticalScrollIndicator;
            visible = _verticalScrollIndicatorVisible;
        }
        
        [indicator setAlpha:1.0f];

        if ([animation completed] && !visible) {
            [indicator removeFromSuperview];
        }
    }
}

- (void)animationUpdated:(XNAnimation *)animation {
    if (animation == _scrollAnimation) {
        // This is a bit of a hack, but it's easier than adding bounceless
        // support to the animation itself. Instead, just cap the values from
        // the animation to what they should be for when bouncing is disabled.

        BOOL effectiveHorizontal = [self _effectiveBouncesHorizontally];
        BOOL effectiveVertical = [self _effectiveBouncesVertically];

        if (!effectiveHorizontal || !effectiveVertical) {
            CGRect scrollBounds = [self _effectiveScrollBounds];
            CGPoint offset = [self contentOffset];
            CGPoint constrained = [self _constrainContentOffset:offset toScrollBounds:scrollBounds elastic:NO];

            if (!effectiveHorizontal) {
                offset.x = constrained.x;
            }

            if (!effectiveVertical) {
                offset.y = constrained.y;
            }

            [self setContentOffset:offset];
        }
    }
}

#pragma mark - Private Methods

- (void)_layoutIndicator:(XNScrollViewIndicator *)indicator dimension:(CGFloat)dimension contentDimension:(CGFloat)contentDimension position:(CGFloat)position startContentInset:(CGFloat)startContentInset endContentInset:(CGFloat)endContentInset otherVisible:(BOOL)other otherDimension:(CGFloat)otherDimension otherOffset:(CGFloat)otherOffset insetStart:(CGFloat)insetStart insetEnd:(CGFloat)insetEnd insetOppositeStart:(CGFloat)insetOppositeStart insetOppositeEnd:(CGFloat)insetOppositeEnd rotate:(BOOL)rotate {
    CGFloat edge = (other ? kXNScrollViewIndicatorCornerDimension : 0) + (insetStart + insetEnd);

    position = position + startContentInset;

    CGFloat indicatorDimension = dimension - edge;
    CGFloat indicatorContentDimension = contentDimension - edge;
    CGFloat indicatorPosition = position * (indicatorContentDimension / contentDimension);

    CGFloat length = [self _lengthForIndicatorWithDimension:indicatorDimension contentDimension:indicatorContentDimension position:indicatorPosition];
    CGFloat pos = [self _positionForIndicatorWithDimension:indicatorDimension contentDimension:indicatorContentDimension position:indicatorPosition];

    CGRect frame = CGRectZero;
    frame.origin.x = insetStart + pos + position - startContentInset;
    frame.size.width = length;
    frame.size.height = kXNScrollViewIndicatorMinimumDimension;
    frame.origin.y = otherDimension + otherOffset - kXNScrollViewIndicatorMinimumDimension - insetOppositeEnd;

    if (rotate) {
        CGRect rotatedFrame = CGRectZero;
        rotatedFrame.origin.y = frame.origin.x;
        rotatedFrame.origin.x = frame.origin.y;
        rotatedFrame.size.height = frame.size.width;
        rotatedFrame.size.width = frame.size.height;
        frame = rotatedFrame;
    }

    [indicator setFrame:frame];

    [self bringSubviewToFront:indicator];
}

- (void)_layoutScrollIndicators {
    CGRect bounds = [self bounds];
    CGRect scrollBounds = [self _effectiveScrollBounds];
    CGPoint contentOffset = [self contentOffset];
    UIEdgeInsets contentInset = [self contentInset];
    UIEdgeInsets indicatorInsets = [self scrollIndicatorInsets];
    
    BOOL horizontalVisible = [self _effectiveShowsHorizontalScrollIndicator];
    BOOL verticalVisible = [self _effectiveShowsVerticalScrollIndicator];

    if (horizontalVisible) {
        [self _layoutIndicator:_horizontalScrollIndicator dimension:bounds.size.width contentDimension:scrollBounds.size.width position:contentOffset.x startContentInset:contentInset.left endContentInset:contentInset.right otherVisible:verticalVisible otherDimension:bounds.size.height otherOffset:contentOffset.y insetStart:indicatorInsets.left insetEnd:indicatorInsets.right insetOppositeStart:indicatorInsets.top insetOppositeEnd:indicatorInsets.bottom rotate:NO];
    }

    if (verticalVisible) {
        [self _layoutIndicator:_verticalScrollIndicator dimension:bounds.size.height contentDimension:scrollBounds.size.height position:contentOffset.y startContentInset:contentInset.top endContentInset:contentInset.bottom otherVisible:horizontalVisible otherDimension:bounds.size.width otherOffset:contentOffset.x insetStart:indicatorInsets.top insetEnd:indicatorInsets.bottom insetOppositeStart:indicatorInsets.left insetOppositeEnd:indicatorInsets.right rotate:YES];
    }
}

- (void)_updateIndicator:(XNScrollViewIndicator *)indicator visible:(BOOL)visible wasVisible:(BOOL)wasVisible animation:(XNAnimation *)animation animated:(BOOL)animated {
    [indicator setIndicatorStyle:[self indicatorStyle]];

    [indicator removeXNAnimation:animation];

    if (wasVisible != visible) {
        if (visible) {
            [self addSubview:indicator];

            if (animated) {
                [indicator setAlpha:0.0f];

                [animation setDuration:kXNScrollViewIndicatorAnimationDuration];
                [animation setFromValue:[NSNumber numberWithFloat:0.0f]];
                [animation setToValue:[NSNumber numberWithFloat:1.0f]];
                [indicator addXNAnimation:animation];
            }
        } else {
            if (animated) {
                [animation setDuration:kXNScrollViewIndicatorAnimationDuration];
                [animation setFromValue:[NSNumber numberWithFloat:1.0f]];
                [animation setToValue:[NSNumber numberWithFloat:0.0f]];
                [indicator addXNAnimation:animation];
            } else {
                [indicator removeFromSuperview];
            }
        }
    }
}

- (void)_updateIndicatorsVisible:(BOOL)visible animated:(BOOL)animated {
    [self _layoutScrollIndicators];

    BOOL horizontalVisible = (visible && [self _effectiveShowsHorizontalScrollIndicator]);
    BOOL verticalVisible = (visible && [self _effectiveShowsVerticalScrollIndicator]);
    [self _updateIndicator:_horizontalScrollIndicator visible:horizontalVisible wasVisible:_horizontalScrollIndicatorVisible animation:_horizontalScrollIndicatorAnimation animated:animated];
    [self _updateIndicator:_verticalScrollIndicator visible:verticalVisible wasVisible:_verticalScrollIndicatorVisible animation:_verticalScrollIndicatorAnimation animated:animated];
    _horizontalScrollIndicatorVisible = horizontalVisible;
    _verticalScrollIndicatorVisible = verticalVisible;
}

- (void)_hideScrollIndicatorsAfterFlash {
    [self _updateIndicatorsVisible:NO animated:YES];
}

- (void)_cancelScrollIndicatorFlash {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_hideScrollIndicatorsAfterFlash) object:nil];
}

- (void)_updateForGeometryChange {
    if ([self isDecelerating]) {
        [self _updateThrowParameters];
    }

    if (![self isDragging]) {
        CGPoint contentOffset = [self contentOffset];
        CGRect scrollBounds = [self _effectiveScrollBounds];

        if (!CGRectContainsPoint(scrollBounds, contentOffset)) {
            contentOffset = [self _constrainContentOffset:contentOffset toScrollBounds:scrollBounds elastic:NO];
            [self setContentOffset:contentOffset];
        }
    }
}

- (void)_updateThrowParameters {
    CGRect scrollBounds = [self _effectiveScrollBounds];

    NSValue *fromValue = [NSValue valueWithCGPoint:_throwTranslation];
    NSValue *velocityValue = [NSValue valueWithCGPoint:_throwVelocity];
    NSValue *toValue = [XNDecayTimingFunction toValueFromValue:fromValue forVelocity:velocityValue withConstant:[self decelerationRate]];

    CGPoint boundedTranslation = [toValue CGPointValue];
    boundedTranslation = [self _constrainContentOffset:boundedTranslation toScrollBounds:scrollBounds elastic:NO];
    NSValue *boundedToValue = [NSValue valueWithCGPoint:boundedTranslation];

    CGPoint minimum = CGPointMake(CGRectGetMinX(scrollBounds), CGRectGetMinY(scrollBounds));
    NSValue *minimumValue = [NSValue valueWithCGPoint:minimum];
    CGPoint maximum = CGPointMake(CGRectGetMaxX(scrollBounds), CGRectGetMaxY(scrollBounds));
    NSValue *maximumValue = [NSValue valueWithCGPoint:maximum];
    id insideValue = [XNDecayTimingFunction insideValueFromValue:fromValue toValue:boundedToValue minimumValue:minimumValue maximumValue:maximumValue];

    XNDecayTimingFunction *timingFunction = (XNDecayTimingFunction *) [_scrollAnimation timingFunction];
    [timingFunction setInsideValue:insideValue];

    [_scrollAnimation setToValue:boundedToValue];
    [_scrollAnimation setFromValue:fromValue];
    [_scrollAnimation setVelocity:velocityValue];
}

- (void)_panFromGestureRecognizer:(UIPanGestureRecognizer *)recognizer {
    NSAssert(recognizer == _panGestureRecognizer, @"invalid recognizer");

    UIGestureRecognizerState state = [_panGestureRecognizer state];

    if (state == UIGestureRecognizerStateBegan) {
        [self stopScrolling];

        [self _delegateWillBeginScrolling];
        [self _delegateWillBeginDragging];
        _dragging = YES;
        _scrolling = YES;

        _previousVelocity = CGPointZero;
        _previousPreviousVelocity = CGPointZero;

        [self _cancelScrollIndicatorFlash];
        [self _updateIndicatorsVisible:YES animated:NO];

        _panStartContentOffset = [self contentOffset];
    } else if (state == UIGestureRecognizerStateCancelled) {
        _dragging = NO;
        _scrolling = NO;
        [self _delegateDidEndDraggingWillDecelerate:NO];
        [self _delegateDidEndScrolling];
    } else {
        CGRect scrollBounds = [self _effectiveScrollBounds];

        CGPoint velocity = [_panGestureRecognizer velocityInView:self];
        velocity.x = -velocity.x;
        velocity.y = -velocity.y;

        CGPoint translation = [_panGestureRecognizer translationInView:self];
        translation.x = _panStartContentOffset.x - translation.x;
        translation.y = _panStartContentOffset.y - translation.y;

        translation = [self _constrainContentOffset:translation toScrollBounds:scrollBounds elastic:YES];

        if (state == UIGestureRecognizerStateChanged) {
            _previousVelocity = velocity;
            _previousPreviousVelocity = _previousVelocity;
          
            [self setContentOffset:translation];
        } else if (state == UIGestureRecognizerStateEnded) {
            CGFloat factor = kXNScrollViewDecelerationCurrentVelocityFactor;
            velocity.x = _previousPreviousVelocity.x * (1 - factor) + velocity.x * factor;
            velocity.y = _previousPreviousVelocity.y *  (1 - factor) + velocity.y * factor;
          
            CGFloat scalarVelocity = sqrtf(velocity.x * velocity.x + velocity.y * velocity.y);
            BOOL stopped = (scalarVelocity <= kXNScrollViewDecelerationMinimumVelocity);
            
            BOOL inside = CGRectContainsPoint(scrollBounds, translation);

            if (!stopped || !inside) {
                _throwVelocity = velocity;
                _throwTranslation = translation;

                [self _updateThrowParameters];

                _dragging = NO;

                [self _delegateDidEndDraggingWillDecelerate:YES];
                [self _delegateWillBeginDecelerating];
                [self addXNAnimation:_scrollAnimation];

                _decelerating = YES;
            } else {
                _dragging = NO;
                _scrolling = NO;
                [self _delegateDidEndDraggingWillDecelerate:NO];
                [self _delegateDidEndScrolling];

                [self _updateIndicatorsVisible:NO animated:YES];
            }
        }
    }
}

@end
