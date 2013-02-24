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

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed duration:(CGFloat)duration complete:(BOOL *)outComplete {
    [super simulateIndex:i elapsed:elapsed duration:duration complete:outComplete];

    CGFloat x = (elapsed / duration);

    if (x >= 1.0) {
        *outComplete = YES;
        return 1.0;
    } else {
        *outComplete = NO;
        return x;
    }
}

@end
