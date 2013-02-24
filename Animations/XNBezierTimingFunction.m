//
//  XNBezierTimingFunction.m
//  Animations
//
//  Created by Grant Paul on 11/25/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNBezierTimingFunction.h"

const static NSInteger kXNBezierTimingFunctionNewtonsMethodIterations = 4;

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
    NSValue *twoValue = [NSValue valueWithCGPoint:CGPointMake(0.58, 1.0)];

    NSArray *points = [NSArray arrayWithObjects:oneValue, twoValue, nil];
    return points;
}

+ (NSArray *)controlPointsEaseInOut {
    NSValue *oneValue = [NSValue valueWithCGPoint:CGPointMake(0.42, 0)];
    NSValue *twoValue = [NSValue valueWithCGPoint:CGPointMake(0.58, 1.0)];

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

- (CGPoint)bezierDerivativeAtTime:(CGFloat)t {
    CGPoint result = CGPointZero;

    NSUInteger n = [_completeControlPoints count] - 1;

    for (NSUInteger i = 0; i <= (n - 1); i++) {
        NSValue *pointValue = [_completeControlPoints objectAtIndex:i];
        CGPoint point = [pointValue CGPointValue];

        NSValue *nextPointValue = [_completeControlPoints objectAtIndex:(i + 1)];
        CGPoint nextPoint = [nextPointValue CGPointValue];

        CGFloat b = nCr((n - 1), i) * powf(t, i) * powf(1 - t, (n - 1) - i);
        result.x += n * (nextPoint.x - point.x) * b;
        result.y += n * (nextPoint.y - point.y) * b;
    }

    return result;
}

- (CGPoint)bezierAtTime:(CGFloat)t {
    CGPoint result = CGPointZero;

    NSUInteger n = [_completeControlPoints count] - 1;

    for (NSUInteger i = 0; i <= n; i++) {
        NSValue *pointValue = [_completeControlPoints objectAtIndex:i];
        CGPoint point = [pointValue CGPointValue];

        CGFloat b = nCr(n, i) * powf(t, i) * powf(1 - t, n - i);
        result.x += point.x * b;
        result.y += point.y * b;
    }

    return result;
}

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed duration:(CGFloat)duration complete:(BOOL *)outComplete {
    [super simulateIndex:i elapsed:elapsed duration:duration complete:outComplete];

    CGPoint result = CGPointZero;
    CGFloat t = (elapsed / duration);
    
    CGFloat a = t;
    for (NSInteger i = 0; i < kXNBezierTimingFunctionNewtonsMethodIterations; i++) {
        result = [self bezierAtTime:a];
        CGPoint deriv = [self bezierDerivativeAtTime:a];

        a = a - ((result.x - t) / deriv.x);
    }

    CGFloat x = result.y;

    if (t >= 1.0) {
        *outComplete = YES;
        return 1.0;
    } else {
        *outComplete = NO;
        return x;
    }
}

@end

