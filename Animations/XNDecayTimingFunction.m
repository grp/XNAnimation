//
//  XNDecayTimingFunction.m
//  Animations
//
//  Created by Grant Paul on 11/28/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNKeyValueExtractor.h"
#import "XNDecayTimingFunction.h"

@implementation XNDecayTimingFunction {
    CGFloat _constant;
}

@synthesize constant = _constant;

+ (CGFloat)toFrom:(CGFloat)from velocity:(CGFloat)velocity constant:(CGFloat)constant {
    if (velocity == 0) {
        return from;
    }

    CGFloat sensitivity = 0.05;

    CGFloat c = constant;
    CGFloat v0 = fabs(velocity);
    CGFloat t = logf(sensitivity / v0) / -c;

    // Integrate up to ending time.
    CGFloat x = v0 * (1 - powf(M_E, -c * t)) / c;

    if (velocity < 0) {
        x = -x;
    }

    x = from + x;

    //NSLog(@"from %f, velocity %f, to %f", from, velocity, x);
    return x;
}

+ (id)toValueFromValue:(id)from forVelocity:(id)velocity withConstant:(CGFloat)constant {
    XNKeyValueExtractor *kve = [[XNKeyValueExtractor alloc] init];

    NSArray *velocityComponents = [kve componentsForObject:velocity];
    NSArray *fromComponents = [kve componentsForObject:from];
    NSMutableArray *toComponents = [NSMutableArray array];

    for (NSInteger i = 0; i < [fromComponents count]; i++) {
        NSNumber *velocityValue = [velocityComponents objectAtIndex:i];
        NSNumber *fromValue = [fromComponents objectAtIndex:i];

        CGFloat v = [velocityValue floatValue];
        CGFloat f = [fromValue floatValue];
        
        CGFloat to = [self toFrom:f velocity:v constant:constant];
        NSNumber *toValue = [NSNumber numberWithFloat:to];

        [toComponents addObject:toValue];
    }

    id to = [kve objectFromComponents:toComponents templateObject:velocity];

    [kve release];

    return to;
}

+ (id)timingFunctionWithConstant:(CGFloat)constant {
    XNDecayTimingFunction *timingFunction = [self timingFunction];
    [timingFunction setConstant:constant];
    return timingFunction;
}

- (id)init {
    if ((self = [super init])) {
        _constant = 0.998;
    }

    return self;
}

- (CGFloat)simulateWithTimeInterval:(NSTimeInterval)dt velocity:(CGFloat)velocity from:(CGFloat)from to:(CGFloat)to complete:(BOOL *)outComplete {
    [super simulateWithTimeInterval:dt velocity:velocity from:from to:to complete:outComplete];

    if (to - from == 0) {
        *outComplete = YES;
        return to;
    }

    CGFloat c = _constant;
    CGFloat t = [self elapsed];
    CGFloat v0 = velocity;

    CGFloat v = v0 * powf(M_E, -c * t);
    CGFloat x = from + v0 * (1 - powf(M_E, -c * t)) / c;

    //NSLog(@"x = %f, v = %f; initial %f; v / v0 = %f", x - from, v, v0, v / v0);

    if (fabs(x - to) <= 0.05) {
        *outComplete = YES;
        return to;
    } else {
        *outComplete = NO;
        return x;
    }
}

@end
