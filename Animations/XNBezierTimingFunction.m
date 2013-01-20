//
//  XNBezierTimingFunction.m
//  Animations
//
//  Created by Grant Paul on 11/25/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNBezierTimingFunction.h"

@implementation XNBezierTimingFunction {
    NSArray *_controlPoints;
    NSArray *_completeControlPoints;
}

@synthesize controlPoints = _controlPoints;

- (void)setControlPoints:(NSArray *)controlPoints {
    [_controlPoints release];
    _controlPoints = [controlPoints copy];

    NSValue *start = [NSValue valueWithCGPoint:CGPointMake(0, 0)];
    NSValue *end = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];

    NSMutableArray *points = [NSMutableArray arrayWithObject:start];
    [points addObjectsFromArray:_controlPoints];
    [points addObject:end];

    [_completeControlPoints release];
    _completeControlPoints = [points copy];
}

+ (NSArray *)controlPointsEaseIn {
    NSValue *oneValue = [NSValue valueWithCGPoint:CGPointMake(0.42, 0)];
    NSValue *twoValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];

    NSArray *points = [NSArray arrayWithObjects:oneValue, twoValue, nil];
    return points;
}

+ (NSArray *)controlPointsEaseOut {
    NSValue *oneValue = [NSValue valueWithCGPoint:CGPointMake(0, 0)];
    NSValue *twoValue = [NSValue valueWithCGPoint:CGPointMake(.58, 1.0)];

    NSArray *points = [NSArray arrayWithObjects:oneValue, twoValue, nil];
    return points;
}

+ (NSArray *)controlPointsEaseInOut {
    NSValue *oneValue = [NSValue valueWithCGPoint:CGPointMake(0.42, 0)];
    NSValue *twoValue = [NSValue valueWithCGPoint:CGPointMake(.58, 1.0)];

    NSArray *points = [NSArray arrayWithObjects:oneValue, twoValue, nil];
    return points;
}

+ (id)timingFunctionWithControlPoints:(NSArray *)points {
    XNBezierTimingFunction *timingFunction = [self timingFunction];
    [timingFunction setControlPoints:points];
    return timingFunction;
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [super copyWithZone:zone];
    [copy setControlPoints:[self controlPoints]];
    return copy;
}

- (id)init {
    if ((self = [super init])) {
        [self setControlPoints:[[self class] controlPointsEaseInOut]];
    }

    return self;
}

- (void)dealloc {
    [_completeControlPoints release];
    [_controlPoints release];

    [super dealloc];
}

// Not sure how this works, but it does. Found online somewhere.
#define nCr(n, r) round(exp((lgamma(n+1)) - (lgamma(r+1) + lgamma(n-r+1))))
#define B(n, i, t) nCr(n, i) * powf(t, i) * powf(1 - t, n - i)

- (CGFloat)velocityIndex:(NSUInteger)i from:(CGFloat)from to:(CGFloat)to             duration:(CGFloat)duration additional:(id)additional {
    CGPoint result = CGPointZero;

    // calculate the derivative of the bezier curve at t=0

    CGFloat t = 0;
    NSUInteger n = [_completeControlPoints count] - 1;

    for (NSUInteger i = 0; i <= n - 1; i++) {
        NSValue *pointValue = [_completeControlPoints objectAtIndex:i];
        CGPoint point = [pointValue CGPointValue];

        NSValue *point2Value = [_completeControlPoints objectAtIndex:(i + 1)];
        CGPoint point2 = [point2Value CGPointValue];

        result.x += n * (point2.x - point.x) * B(n - 1, i, t);
        result.y += n * (point2.y - point.y) * B(n - 1, i, t);
    }

    CGFloat v = from + (to - from) * result.y;

    return v;
}

- (CGFloat)durationIndex:(NSUInteger)i from:(CGFloat)from to:(CGFloat)to             velocity:(CGFloat)velocity additional:(id)additional {
    [NSException raise:@"XNBezierTimingFunctionException" format:@"bezier curves are defined by their control points, not velocity"];
    return 0;
}

- (CGFloat)toIndex:(NSUInteger)i       from:(CGFloat)from duration:(CGFloat)duration velocity:(CGFloat)velocity additional:(id)additional {
    [NSException raise:@"XNBezierTimingFunctionException" format:@"bezier curves are defined by their control points, not velocity"];
    return 0;
}

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed from:(CGFloat)from to:(CGFloat)to             velocity:(CGFloat)velocity additional:(id)additional complete:(BOOL *)outComplete {
    [NSException raise:@"XNBezierTimingFunctionException" format:@"bezier curves are defined by their control points, not velocity"];
    return 0;
}

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed from:(CGFloat)from duration:(CGFloat)duration velocity:(CGFloat)velocity additional:(id)additional complete:(BOOL *)outComplete {
    [NSException raise:@"XNBezierTimingFunctionException" format:@"bezier curves are defined by their control points, not velocity"];
    return 0;
}

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed from:(CGFloat)from to:(CGFloat)to             duration:(CGFloat)duration additional:(id)additional complete:(BOOL *)outComplete {
    CGPoint result = CGPointZero;

    CGFloat t = (elapsed / duration);
    NSUInteger n = [_completeControlPoints count] - 1;
    
    for (NSUInteger i = 0; i <= n; i++) {
        NSValue *pointValue = [_completeControlPoints objectAtIndex:i];
        CGPoint point = [pointValue CGPointValue];
        
        result.x += point.x * B(n, i, t);
        result.y += point.y * B(n, i, t);
    }

    CGFloat x = from + (to - from) * result.y;

    if (t >= 1.0) {
        *outComplete = YES;
        return to;
    } else {
        *outComplete = NO;
        return x;
    }
}

@end

