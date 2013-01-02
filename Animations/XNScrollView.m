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

const static CGFloat kXNScrollViewDecelerationMinimumVelocity = 25.0f;

const CGFloat XNScrollViewDecelerationRateNormal = 0.998f;
const CGFloat XNScrollViewDecelerationRateFast = 0.990f;

const static CGFloat kXNScrollViewIndicatorMinimumDimension = 9.0f;
const static CGFloat kXNScrollViewIndicatorMinimumInsideLength = 36.0f;
const static CGFloat kXNScrollViewIndicatorCornerDimension = 8.0f;
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
    CGRect insideRect = CGRectInset(rect, 2.0f, 2.0f);
    CGFloat insideShortLength = fminf(insideRect.size.width, insideRect.size.height);

    UIColor *lightColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
    UIColor *darkColor = [UIColor colorWithWhite:0.0f alpha:0.5f];

    if ([self indicatorStyle] == XNScrollViewIndicatorStyleWhite) {
        [lightColor setFill];
    } else {
        [darkColor setFill];
    }

    UIBezierPath *innerPath = [UIBezierPath bezierPathWithRoundedRect:insideRect cornerRadius:(insideShortLength / 2.0f)];
    [innerPath fill];

    if ([self indicatorStyle] == XNScrollViewIndicatorStyleDefault) {
        CGRect outsideRect = CGRectInset(rect, 1.0f, 1.0f);
        CGFloat outsideShortLength = fminf(outsideRect.size.width, outsideRect.size.height);
        
        [lightColor setFill];
        
        UIBezierPath *outerPath = [UIBezierPath bezierPathWithRoundedRect:outsideRect cornerRadius:(outsideShortLength / 2.0f)];
        [outerPath appendPath:innerPath];
        [outerPath setUsesEvenOddFillRule:YES];
        [outerPath fill];
    }
}

@end

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

    UIEdgeInsets _scrollIndicatorInsets;
    XNScrollViewIndicatorStyle _indicatorStyle;
    XNScrollViewIndicator *_horizontalScrollIndicator;
    XNScrollViewIndicator *_verticalScrollIndicator;
    XNAnimation *_horizontalScrollIndicatorAnimation;
    XNAnimation *_verticalScrollIndicatorAnimation;

    struct {
        BOOL __scrollEnabled:1;
#define _scrollEnabled _flags.__scrollEnabled

        BOOL __showsHorizontalScrollIndicator;
#define _showsHorizontalScrollIndicator _flags.__showsHorizontalScrollIndicator
        BOOL __showsVerticalScrollIndicator;
#define _showsVerticalScrollIndicator _flags.__showsVerticalScrollIndicator

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
        [_horizontalScrollIndicator setHidden:YES];
        _verticalScrollIndicator = [[XNScrollViewIndicator alloc] init];
        [_verticalScrollIndicator setHidden:YES];

        XNBezierTimingFunction *timingFunction = [XNBezierTimingFunction timingFunctionWithControlPoints:[XNBezierTimingFunction controlPointsEaseInOut]];
        _horizontalScrollIndicatorAnimation = [[XNAnimation alloc] initWithKeyPath:@"alpha"];
        [_horizontalScrollIndicatorAnimation setTimingFunction:timingFunction];
        [_horizontalScrollIndicatorAnimation setDelegate:self];
        _verticalScrollIndicatorAnimation = [[XNAnimation alloc] initWithKeyPath:@"alpha"];
        [_verticalScrollIndicatorAnimation setTimingFunction:timingFunction];
        [_verticalScrollIndicatorAnimation setDelegate:self];

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

- (BOOL)_effectiveScrollsHorizontally {
    CGRect bounds = [self bounds];
    CGSize contentSize = [self contentSize];
    UIEdgeInsets contentInset = [self contentInset];

    return (contentInset.left + contentSize.width + contentInset.right > bounds.size.width);
}

- (BOOL)_effectiveScrollsVertically {
    CGRect bounds = [self bounds];
    CGSize contentSize = [self contentSize];
    UIEdgeInsets contentInset = [self contentInset];

    return (contentInset.top + contentSize.height + contentInset.bottom > bounds.size.height);
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

#pragma mark - Graphical Computation

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

- (CGFloat)_lengthForIndicatorWithDimension:(CGFloat)dimension contentDimension:(CGFloat)contentDimension position:(CGFloat)position {
    CGFloat outside = 0;
    CGFloat minimum = kXNScrollViewIndicatorMinimumInsideLength;

    if (position < 0) {
        outside = fabs(position);
        minimum = kXNScrollViewIndicatorMinimumDimension;
    } else if (position > contentDimension) {
        outside = fabs(position - contentDimension);
        minimum = kXNScrollViewIndicatorMinimumDimension;
    }

    CGFloat partialDisplayed = (dimension / (contentDimension + dimension));
    CGFloat length = dimension * partialDisplayed;
    length = fmax(length, kXNScrollViewIndicatorMinimumInsideLength);
    length = length - outside;
    length = fmax(length, minimum);
    return length;
}

- (CGFloat)_positionForIndicatorWithDimension:(CGFloat)dimension contentDimension:(CGFloat)contentDimension position:(CGFloat)position {
    CGFloat length = [self _lengthForIndicatorWithDimension:dimension contentDimension:contentDimension position:position];

    CGFloat partialPosition = (position / (contentDimension + dimension));
    CGFloat pos = dimension * partialPosition;
    
    if (position > contentDimension) {
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
        
        if (animation == _horizontalScrollIndicatorAnimation) {
            indicator = _horizontalScrollIndicator;
        } else if (animation == _verticalScrollIndicatorAnimation) {
            indicator = _verticalScrollIndicator;
        }

        // This is quite a bit of a hack; there should be a better way to get
        // the needed context to figure out which direction we are going in.
        BOOL hidden = [[animation fromValue] floatValue] == 0.0f;
        
        [indicator setHidden:hidden];
        [indicator setAlpha:1.0f];

        if ([animation completed]) {
            if (!hidden) {
                [indicator removeFromSuperview];
                [indicator setHidden:YES];
            } else {
                [indicator setHidden:NO];
            }
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

        [self _layoutScrollIndicators];
    }
}

#pragma mark - Private Methods

- (void)_layoutIndicator:(XNScrollViewIndicator *)indicator dimension:(CGFloat)dimension contentDimension:(CGFloat)contentDimension position:(CGFloat)position otherVisible:(BOOL)other otherDimension:(CGFloat)otherDimension otherOffset:(CGFloat)otherOffset insetStart:(CGFloat)insetStart insetEnd:(CGFloat)insetEnd insetOppositeStart:(CGFloat)insetOppositeStart insetOppositeEnd:(CGFloat)insetOppositeEnd rotate:(BOOL)rotate {
    CGFloat edge = (other ? kXNScrollViewIndicatorCornerDimension : 0) + (insetStart + insetEnd);

    CGFloat indicatorDimension = dimension - edge;
    CGFloat indicatorContentDimension = contentDimension - edge;
    CGFloat indicatorPosition = position * (contentDimension / indicatorContentDimension);

    CGFloat length = [self _lengthForIndicatorWithDimension:indicatorDimension contentDimension:indicatorContentDimension position:indicatorPosition];
    CGFloat pos = [self _positionForIndicatorWithDimension:indicatorDimension contentDimension:indicatorContentDimension position:indicatorPosition];

    CGRect frame = CGRectZero;
    frame.origin.x = insetStart + pos + position;
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
}

- (void)_layoutScrollIndicators {
    CGRect bounds = [self bounds];
    CGRect scrollBounds = [self _effectiveScrollBounds];
    CGPoint contentOffset = [self contentOffset];
    UIEdgeInsets indicatorInsets = [self scrollIndicatorInsets];
    
    BOOL horizontalVisible = [self _effectiveShowsHorizontalScrollIndicator];
    BOOL verticalVisible = [self _effectiveShowsVerticalScrollIndicator];

    [self _layoutIndicator:_horizontalScrollIndicator dimension:bounds.size.width contentDimension:scrollBounds.size.width position:contentOffset.x otherVisible:verticalVisible otherDimension:bounds.size.height otherOffset:contentOffset.y insetStart:indicatorInsets.left insetEnd:indicatorInsets.right insetOppositeStart:indicatorInsets.top insetOppositeEnd:indicatorInsets.bottom rotate:NO];
    [self _layoutIndicator:_verticalScrollIndicator dimension:bounds.size.height contentDimension:scrollBounds.size.height position:contentOffset.y otherVisible:horizontalVisible otherDimension:bounds.size.width otherOffset:contentOffset.x insetStart:indicatorInsets.top insetEnd:indicatorInsets.bottom insetOppositeStart:indicatorInsets.left insetOppositeEnd:indicatorInsets.right rotate:YES];
}

- (void)_updateIndicator:(XNScrollViewIndicator *)indicator visible:(BOOL)visible animation:(XNAnimation *)animation animated:(BOOL)animated {
    [indicator setIndicatorStyle:[self indicatorStyle]];

    [indicator removeXNAnimation:animation];

    if ([indicator isHidden] != !visible) {
        if (visible) {
            [self addSubview:indicator];
            [indicator setHidden:NO];

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
                [indicator setHidden:YES];
            }
        }
    }
}

- (void)_updateIndicatorsVisible:(BOOL)visible animated:(BOOL)animated {
    [self _layoutScrollIndicators];

    BOOL horizontalVisible = (visible && [self _effectiveShowsHorizontalScrollIndicator]);
    BOOL verticalVisible = (visible && [self _effectiveShowsVerticalScrollIndicator]);
    [self _updateIndicator:_horizontalScrollIndicator visible:horizontalVisible animation:_horizontalScrollIndicatorAnimation animated:animated];
    [self _updateIndicator:_verticalScrollIndicator visible:verticalVisible animation:_verticalScrollIndicatorAnimation animated:animated];
}

- (void)_hideScrollIndicatorsAfterFlash {
    [self _updateIndicatorsVisible:NO animated:YES];
}

- (void)_cancelScrollIndicatorFlash {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_hideScrollIndicatorsAfterFlash) object:nil];
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
            [self setContentOffset:translation];

            [self _layoutScrollIndicators];
        } else if (state == UIGestureRecognizerStateEnded) {
            CGFloat scalarVelocity = sqrtf(velocity.x * velocity.x + velocity.y * velocity.y);
            BOOL stopped = (scalarVelocity <= kXNScrollViewDecelerationMinimumVelocity);
            BOOL inside = CGRectContainsPoint(scrollBounds, translation);

            if (!stopped || !inside) {
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
                id insideValue = [XNDecayTimingFunction insideValueFromValue:fromValue toValue:boundedToValue minimumValue:minimumValue maximumValue:maximumValue];

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
