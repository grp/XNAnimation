//
//  XNTimingFunction.m
//  Animations
//
//  Created by Grant Paul on 11/24/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNTimingFunction.h"

@implementation XNTimingFunction

+ (id)timingFunction {
    return [[[self alloc] init] autorelease];
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] alloc] init];
    return copy;
}

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed duration:(CGFloat)duration complete:(BOOL *)outComplete {
    if (elapsed >= duration) {
        *outComplete = YES;
        return 1.0;
    } else {
        *outComplete = NO;
        return 0.0;
    }
}

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed velocity:(CGFloat)velocity complete:(BOOL *)outComplete {
    *outComplete = YES;
    return 1.0;
}

- (NSArray *)simulateWithTimeInterval:(NSTimeInterval)dt elapsed:(NSTimeInterval)elapsed durations:(NSArray *)durations velocities:(NSArray *)velocities fromComponents:(NSArray *)fromComponents toComponents:(NSArray *)toComponents complete:(BOOL *)outComplete {
    if ((fromComponents == nil || fromComponents == nil) || (velocities == nil && durations == nil)) {
        [NSException raise:@"XNTimingFunctionMissingComponentsException" format:@"from, to, and duration/velocity must be provided"];
    }

    if (([fromComponents count] != [toComponents count]) ||
        (durations != nil && ([fromComponents count] != [durations count] || [toComponents count] != [durations count])) ||
        (velocities != nil && ([fromComponents count] != [velocities count] || [toComponents count] != [velocities count]))) {
        [NSException raise:@"XNTimingFunctionVariableDimensionsException" format:@"from, to, and duration/velocity must all be of the same dimensions"];
    }

    NSMutableArray *positions = [NSMutableArray array];
    if (outComplete != NULL) {
        *outComplete = YES;
    }

    for (NSUInteger i = 0; i < [fromComponents count]; i++) {
        NSNumber *fromValue = [fromComponents objectAtIndex:i];
        NSNumber *toValue = [toComponents objectAtIndex:i];
        
        CGFloat from = [fromValue floatValue];
        CGFloat to = [toValue floatValue];
        CGFloat range = (to - from);

        BOOL complete = NO;
        CGFloat position = 0;

        NSNumber *velocityValue = [velocities objectAtIndex:i];
        NSNumber *durationValue = [durations objectAtIndex:i];

        if (velocityValue != nil) {
            CGFloat velocity = [velocityValue floatValue];
            velocity = velocity / range;
            if (range == 0) velocity = 0;
            position = [self simulateIndex:i elapsed:elapsed velocity:velocity complete:&complete];
        } else if (durationValue != nil) {
            CGFloat duration = [durationValue floatValue];
            position = [self simulateIndex:i elapsed:elapsed duration:duration complete:&complete];
        }

        position = from + position * range;

        NSAssert(!isnan(position), @"position cannot be NaN");

        if (outComplete != NULL) {
            *outComplete = (*outComplete && complete);
        }

        NSNumber *positionValue = [NSNumber numberWithFloat:position];
        [positions addObject:positionValue];
    }
    
    return positions;
}

@end
