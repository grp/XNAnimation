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

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed duration:(CGFloat)duration from:(CGFloat)from to:(CGFloat)to complete:(BOOL *)outComplete {
    [super simulateIndex:i elapsed:elapsed duration:duration from:from to:to complete:outComplete];

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

@end
