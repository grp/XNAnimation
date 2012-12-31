//
//  XNScrollView.m
//  Animations
//
//  Created by Grant Paul on 12/30/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNScrollView.h"

// iOS 6 introduces a new formula for this, depending on the dimensions of the
// scroll view as well as a constant. This option can either emulate that new
// behavior or the previous simple scaling by the defined elastic constant.
const static BOOL kXNScrollViewElasticSimpleFormula = NO;
const static CGFloat kXNScrollViewElasticConstant = 0.55f;

const CGFloat XNScrollViewDecelerationRateNormal = 0.998f;
const CGFloat XNScrollViewDecelerationRateFast = 0.990f;

@interface XNScrollView () <XNAnimationDelegate>
@end

@implementation XNScrollView {
    CGSize _contentSize;
    CGPoint _contentOffset;
    XNAnimation *_offsetAnimation;

    CGFloat _decelerationRate;

    UIPanGestureRecognizer *_panGestureRecognizer;
    CGPoint _panStartContentOffset;
    XNAnimation *_scrollAnimation;
    
    struct {
        BOOL __scrollEnabled:1;
#define _scrollEnabled _flags.__scrollEnabled

        BOOL __bounces:1;
#define _bounces _flags.__bounces
        BOOL __alwaysBounceHorizontal:1;
#define _alwaysBounceHorizontal _flags.__alwaysBounceHorizontal
        BOOL __alwaysBounceVertical:1;
#define _alwaysBounceVertical _flags.__alwaysBounceVertical

        BOOL __dragging:1;
#define _dragging _flags.__dragging
        BOOL __decelerating:1;
#define _decelerating _flags.__dragging
        BOOL __scrolling:1;
#define _scrolling _flags.__dragging
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
@synthesize panGestureRecognizer = _panGestureRecognizer;
@synthesize decelerationRate = _decelerationRate;

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

- (CGPoint)contentOffset {
    return [self bounds].origin;
}

- (void)setContentOffset:(CGPoint)contentOffset {
    CGRect bounds = [self bounds];
    bounds.origin = contentOffset;
    [self setBounds:bounds];

    [self _delegateDidScroll];
}

- (void)setDecelerationRate:(CGFloat)decelerationRate {
    _decelerationRate = decelerationRate;

    XNDecayTimingFunction *timingFunction = (XNDecayTimingFunction *) [_scrollAnimation timingFunction];
    [timingFunction setConstant:decelerationRate];
}

- (BOOL)bounces {
    return _bounces;
}

- (void)setBounces:(BOOL)bounces {
    _bounces = bounces;
}

- (BOOL)alwaysBounceHorizontal {
    return _alwaysBounceHorizontal;
}

- (void)setAlwaysBounceHorizontal:(BOOL)alwaysBounceHorizontal {
    _alwaysBounceHorizontal = alwaysBounceHorizontal;
}

- (BOOL)alwaysBounceVertical {
    return _alwaysBounceVertical;
}

- (void)setAlwaysBounceVertical:(BOOL)alwaysBounceVertical {
    _alwaysBounceVertical = alwaysBounceVertical;
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

- (BOOL)isScrollEnabled {
    return _scrollEnabled;
}

- (void)setScrollEnabled:(BOOL)scrollEnabled {
    _scrollEnabled = scrollEnabled;

    if (![self isScrollEnabled] && [self isScrolling]) {
        [self stopScrolling];
    }
}

#pragma mark - Methods

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    if (animated) {
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

- (void)stopScrolling {
    if (_dragging && [_panGestureRecognizer state] != UIGestureRecognizerStateBegan) {
        [_panGestureRecognizer setEnabled:NO];
        [_panGestureRecognizer setEnabled:YES];
    }
    
    [self removeXNAnimation:_scrollAnimation];
    [self removeXNAnimation:_offsetAnimation];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _scrollEnabled = YES;
        _bounces = YES;

        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_panFromGestureRecognizer:)];
        [_panGestureRecognizer setMaximumNumberOfTouches:1];
        [_panGestureRecognizer setCancelsTouchesInView:YES];
        [self addGestureRecognizer:_panGestureRecognizer];

        _scrollAnimation = [[XNAnimation alloc] initWithKeyPath:@"contentOffset"];
        [_scrollAnimation setTimingFunction:[XNDecayTimingFunction timingFunction]];
        [self setDecelerationRate:XNScrollViewDecelerationRateNormal];
        [_scrollAnimation setDelegate:self];

        _offsetAnimation = [[XNAnimation alloc] initWithKeyPath:@"contentOffset"];
        [_offsetAnimation setTimingFunction:[XNSpringTimingFunction timingFunction]];
        [_offsetAnimation setDelegate:self];
    }

    return self;
}

- (void)dealloc {
    [self stopScrolling];

    [_panGestureRecognizer release];
    [_scrollAnimation release];
    [_offsetAnimation release];

    [super dealloc];
}

#pragma mark - Private Methods

- (BOOL)_effectiveBouncesHorizontally {
    CGRect bounds = [self bounds];
    CGSize contentSize = [self contentSize];

    return [self bounces] && ([self alwaysBounceHorizontal] || (contentSize.width > bounds.size.width));
}

- (BOOL)_effectiveBouncesVertically {
    CGRect bounds = [self bounds];
    CGSize contentSize = [self contentSize];

    return [self bounces] && ([self alwaysBounceVertical] || (contentSize.height > bounds.size.height));
}

- (CGRect)_effectiveScrollBounds {
    CGRect bounds = [self bounds];
    CGSize contentSize = [self contentSize];

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

    scrollBounds = UIEdgeInsetsInsetRect(scrollBounds, [self contentInset]);

    return scrollBounds;
}

- (CGFloat)_elasticDistanceForDistance:(CGFloat)distance constant:(CGFloat)constant range:(CGFloat)range {
    if (kXNScrollViewElasticSimpleFormula) {
        distance = distance * constant;
    } else {
        distance = (1.0 - (1.0 / ((distance * constant / range) + 1.0))) * range;
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
        
        CGFloat distance = fabs(offset.x - edge);
        distance = [self _elasticDistanceForDistance:distance constant:horizontalConstant range:range];
        
        offset.x = edge - distance;
    } else if (offset.x > CGRectGetMaxX(scrollBounds)) {
        CGFloat range = [self bounds].size.width;
        CGFloat edge = CGRectGetMaxX(scrollBounds);

        CGFloat distance = fabs(offset.x - edge);
        distance = [self _elasticDistanceForDistance:distance constant:horizontalConstant range:range];

        offset.x = edge + distance;
    }

    if (offset.y < CGRectGetMinY(scrollBounds)) {
        CGFloat range = [self bounds].size.height;
        CGFloat edge = CGRectGetMinY(scrollBounds);

        CGFloat distance = fabs(offset.y - edge);
        distance = [self _elasticDistanceForDistance:distance constant:verticalConstant range:range];

        offset.y = edge - distance;
    } else if (offset.y > CGRectGetMaxY(scrollBounds)) {
        CGFloat range = [self bounds].size.height;
        CGFloat edge = CGRectGetMaxY(scrollBounds);

        CGFloat distance = fabs(offset.y - edge);
        distance = [self _elasticDistanceForDistance:distance constant:verticalConstant range:range];

        offset.y = edge + distance;
    }

    return offset;
}


- (void)animationStopped:(XNAnimation *)animation {
    if (animation == _scrollAnimation) {
        _decelerating = NO;
        _scrolling = NO;
        [self _delegateDidEndDecelerating];
        [self _delegateDidEndScrolling];
    } else if (animation == _offsetAnimation) {
        [self _delegateDidEndScrollingAnimation];
    }
}

- (void)animationUpdated:(XNAnimation *)animation {
    if (animation == _scrollAnimation) {
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

- (void)_panFromGestureRecognizer:(UIPanGestureRecognizer *)recognizer {
    NSAssert(recognizer == _panGestureRecognizer, @"invalid recognizer");

    if (![self isScrollEnabled]) {
        return;
    }

    UIGestureRecognizerState state = [_panGestureRecognizer state];

    if (state == UIGestureRecognizerStateBegan) {
        [self stopScrolling];

        [self _delegateWillBeginScrolling];
        [self _delegateWillBeginDragging];
        _dragging = YES;
        _scrolling = YES;

        _panStartContentOffset = [self contentOffset];
        
        return;
    } else if (state == UIGestureRecognizerStateCancelled) {
        _dragging = NO;
        _scrolling = NO;
        [self _delegateDidEndDraggingWillDecelerate:NO];
        [self _delegateDidEndScrolling];
        
        return;
    }

    CGRect scrollBounds = [self _effectiveScrollBounds];

    CGPoint velocity = [_panGestureRecognizer velocityInView:self];
    velocity.x = -velocity.x;
    velocity.y = -velocity.y;

    CGPoint translation = [_panGestureRecognizer translationInView:self];
    translation.x = _panStartContentOffset.x - translation.x;
    translation.y = _panStartContentOffset.y - translation.y;

    translation = [self _constrainContentOffset:translation toScrollBounds:scrollBounds elastic:YES];

    if (state == UIGestureRecognizerStateChanged) {
        [self setContentOffset:translation];
    } else if (state == UIGestureRecognizerStateEnded) {
        NSValue *fromValue = [NSValue valueWithCGPoint:translation];
        NSValue *velocityValue = [NSValue valueWithCGPoint:velocity];
        NSValue *toValue = [XNDecayTimingFunction toValueFromValue:fromValue forVelocity:velocityValue withConstant:[self decelerationRate]];
        
        CGPoint boundedTranslation = [toValue CGPointValue];
        boundedTranslation = [self _constrainContentOffset:boundedTranslation toScrollBounds:scrollBounds elastic:NO];
        NSValue *boundedToValue = [NSValue valueWithCGPoint:boundedTranslation];

        CGPoint minimum = CGPointMake(CGRectGetMinX(scrollBounds), CGRectGetMinY(scrollBounds));
        NSValue *minimumValue = [NSValue valueWithCGPoint:minimum];
        CGPoint maximum = CGPointMake(CGRectGetMaxX(scrollBounds), CGRectGetMaxY(scrollBounds));
        NSValue *maximumValue = [NSValue valueWithCGPoint:maximum];
        id insideValue = [XNDecayTimingFunction insideValueForValue:fromValue fromValue:minimumValue toValue:maximumValue];

        XNDecayTimingFunction *timingFunction = (XNDecayTimingFunction *) [_scrollAnimation timingFunction];
        [timingFunction setInsideValue:insideValue];

        [_scrollAnimation setToValue:boundedToValue];
        [_scrollAnimation setFromValue:fromValue];
        [_scrollAnimation setVelocity:velocityValue];

        _dragging = NO;

        [self _delegateDidEndDraggingWillDecelerate:YES];
        [self _delegateWillBeginDecelerating];
        [self addXNAnimation:_scrollAnimation];

        _decelerating = YES;

    }
}

@end
