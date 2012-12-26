//
//  XNDecayTimingFunction.m
//  Animations
//
//  Created by Grant Paul on 11/28/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNKeyValueExtractor.h"
#import "XNDecayTimingFunction.h"

const static CGFloat kXNDecayTimingFunctionTemporalSensitivity = 1000.0f;

const static CGFloat kXNDecayTimingFunctionDefaultConstant = 0.998f;
const static CGFloat kXNDecayTimingFunctionDefaultSensitivity = 0.05f;

@implementation XNDecayTimingFunction {
    CGFloat _sensitivity;
    CGFloat _constant;
}

@synthesize sensitivity = _sensitivity;
@synthesize constant = _constant;

+ (CGFloat)toFrom:(CGFloat)from velocity:(CGFloat)velocity constant:(CGFloat)constant sensitivity:(CGFloat)sensitivity {
    if (velocity == 0) {
        return from;
    }

    CGFloat c = constant;
    CGFloat s = sensitivity / kXNDecayTimingFunctionTemporalSensitivity;
    CGFloat v0 = velocity / kXNDecayTimingFunctionTemporalSensitivity;
    CGFloat t = logf(s / fabs(v0)) / logf(c) * kXNDecayTimingFunctionTemporalSensitivity;
    CGFloat x = from + c * v0 * (1 - powf(c, t)) / (1 - c);

    return x;
}

+ (id)toValueFromValue:(id)from forVelocity:(id)velocity withConstant:(CGFloat)constant sensitivity:(CGFloat)sensitivity {
    XNKeyValueExtractor *kve = [[XNKeyValueExtractor alloc] init];

    NSArray *velocityComponents = [kve componentsForObject:velocity];
    NSArray *fromComponents = [kve componentsForObject:from];
    
    NSMutableArray *toComponents = [NSMutableArray array];

    for (NSInteger i = 0; i < [fromComponents count]; i++) {
        NSNumber *velocityValue = [velocityComponents objectAtIndex:i];
        NSNumber *fromValue = [fromComponents objectAtIndex:i];

        CGFloat v = [velocityValue floatValue];
        CGFloat f = [fromValue floatValue];
        
        CGFloat to = [self toFrom:f velocity:v constant:constant sensitivity:sensitivity];
        NSNumber *toValue = [NSNumber numberWithFloat:to];

        [toComponents addObject:toValue];
    }

    id to = [kve objectFromComponents:toComponents templateObject:velocity];

    [kve release];

    return to;
}

+ (id)toValueFromValue:(id)from forVelocity:(id)velocity withConstant:(CGFloat)constant {
    return [self toValueFromValue:from forVelocity:velocity withConstant:constant sensitivity:kXNDecayTimingFunctionDefaultSensitivity];
}

+ (id)timingFunctionWithConstant:(CGFloat)constant sensitivity:(CGFloat)sensitivity {
    XNDecayTimingFunction *timingFunction = [self timingFunction];
    [timingFunction setConstant:constant];
    [timingFunction setSensitivity:sensitivity];
    return timingFunction;
}

+ (id)timingFunctionWithConstant:(CGFloat)constant {
    return [self timingFunctionWithConstant:constant sensitivity:kXNDecayTimingFunctionDefaultSensitivity];
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [super copyWithZone:zone];
    [copy setSensitivity:[self sensitivity]];
    [copy setConstant:[self constant]];
    return copy;
}

- (id)init {
    if ((self = [super init])) {
        _sensitivity = kXNDecayTimingFunctionDefaultSensitivity;
        _constant = kXNDecayTimingFunctionDefaultConstant;
    }

    return self;
}

- (CGFloat)simulateWithTimeInterval:(NSTimeInterval)dt elapsed:(NSTimeInterval)elapsed velocity:(CGFloat)velocity from:(CGFloat)from to:(CGFloat)to complete:(BOOL *)outComplete {
    [super simulateWithTimeInterval:dt elapsed:elapsed velocity:velocity from:from to:to complete:outComplete];

    CGFloat c = _constant;
    CGFloat s = _sensitivity / kXNDecayTimingFunctionTemporalSensitivity;
    CGFloat v0 = velocity / kXNDecayTimingFunctionTemporalSensitivity;
    CGFloat t = elapsed * kXNDecayTimingFunctionTemporalSensitivity;
    CGFloat v = powf(c, t) * v0;
    CGFloat x = from + c * v0 * (1 - powf(c, t)) / (1 - c);

    if (fabs(v) <= s) {
        *outComplete = YES;
        return to;
    } else {
        *outComplete = NO;
        return x;
    }
}

@end
