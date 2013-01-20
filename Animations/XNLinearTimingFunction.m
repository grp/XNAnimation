//
//  XNLinearTimingFunction.m
//  Animations
//
//  Created by Grant Paul on 11/24/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNLinearTimingFunction.h"

@implementation XNLinearTimingFunction

- (id)copyWithZone:(NSZone *)zone {
    id copy = [super copyWithZone:zone];
    return copy;
}

- (CGFloat)velocityIndex:(NSUInteger)i from:(CGFloat)from to:(CGFloat)to             duration:(CGFloat)duration additional:(id)additional {
    return (to - from) / duration;
}

- (CGFloat)durationIndex:(NSUInteger)i from:(CGFloat)from to:(CGFloat)to             velocity:(CGFloat)velocity additional:(id)additional {
    return (to - from) / velocity;
}

- (CGFloat)toIndex:(NSUInteger)i       from:(CGFloat)from duration:(CGFloat)duration velocity:(CGFloat)velocity additional:(id)additional {
    return from + (duration * velocity);
}

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed from:(CGFloat)from to:(CGFloat)to             duration:(CGFloat)duration additional:(id)additional complete:(BOOL *)outComplete {
    CGFloat t = (elapsed / duration);
    CGFloat x = from + (to - from) * t;

    if (t >= 1.0) {
        *outComplete = YES;
        return to;
    } else {
        *outComplete = NO;
        return x;
    }
}

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed from:(CGFloat)from to:(CGFloat)to             velocity:(CGFloat)velocity additional:(id)additional complete:(BOOL *)outComplete {
    CGFloat duration = [self durationIndex:i from:from to:to velocity:velocity additional:additional];
    return [self simulateIndex:i elapsed:elapsed from:from to:to duration:duration additional:additional complete:outComplete];
}

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed from:(CGFloat)from duration:(CGFloat)duration velocity:(CGFloat)velocity additional:(id)additional complete:(BOOL *)outComplete {
    CGFloat to = [self toIndex:i from:from duration:duration velocity:velocity additional:additional];
    return [self simulateIndex:i elapsed:elapsed from:from to:to duration:duration additional:additional complete:outComplete];
}

@end
