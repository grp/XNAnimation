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
const static CGFloat kXNDecayTimingFunctionDefaultBounce = 0.99f;
const static CGFloat kXNDecayTimingFunctionDefaultSensitivity = 0.05f;

@implementation XNDecayTimingFunction {
    NSArray *_insideComponents;

    CGFloat _sensitivity;
    CGFloat _constant;
    CGFloat _bounce;
}

@synthesize insideValue = _insideComponents;

@synthesize sensitivity = _sensitivity;
@synthesize constant = _constant;
@synthesize bounce = _bounce;

static CGFloat XNDecayTimingFunctionSimpleVelocityAtTime(CGFloat c, CGFloat t, CGFloat v0) {
    return powf(c, t) * v0;
}

static CGFloat XNDecayTimingFunctionSimpleDistanceAtTime(CGFloat c, CGFloat t, CGFloat v0, CGFloat x0) {
    return x0 + c * v0 * (1 - powf(c, t)) / (1 - c);
}

static CGFloat XNDecayTimingFunctionBouncingVelocityAtTime(CGFloat c, CGFloat b, CGFloat t, CGFloat v0) {
    return powf(b * c, t) * v0;
}

static CGFloat XNDecayTimingFunctionBouncingDistanceAtTime(CGFloat c, CGFloat b, CGFloat t, CGFloat v0, CGFloat x0, CGFloat xF) {
    return powf(b, t) * x0 + c * powf(b, t) * v0 * (1 - powf(c, t)) / (1 - c) + xF * (1 - powf(b, t));
}

+ (CGFloat)toFrom:(CGFloat)from velocity:(CGFloat)velocity constant:(CGFloat)constant sensitivity:(CGFloat)sensitivity {
    if (velocity == 0) {
        return from;
    }

    CGFloat s = sensitivity / kXNDecayTimingFunctionTemporalSensitivity;
    CGFloat v0 = velocity / kXNDecayTimingFunctionTemporalSensitivity;
    
    CGFloat t = logf(s / fabs(v0)) / logf(constant) * kXNDecayTimingFunctionTemporalSensitivity;
    CGFloat x = XNDecayTimingFunctionSimpleDistanceAtTime(constant, t, v0, from);

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

+ (id)insideValueForValue:(id)value fromValue:(id)fromValue toValue:(id)toValue {
    XNKeyValueExtractor *kve = [[XNKeyValueExtractor alloc] init];
    NSArray *components = [kve componentsForObject:value];
    NSArray *fromComponents = [kve componentsForObject:fromValue];
    NSArray *toComponents = [kve componentsForObject:toValue];
    [kve release];

    NSMutableArray *betweenComponents = [NSMutableArray array];

    for (NSUInteger i = 0; i < [components count]; i++) {
        CGFloat v = [[components objectAtIndex:i] floatValue];
        CGFloat f = [[fromComponents objectAtIndex:i] floatValue];
        CGFloat t = [[toComponents objectAtIndex:i] floatValue];

        NSValue *betweenValue = [NSNumber numberWithBool:(v >= f && v <= t)];
        [betweenComponents addObject:betweenValue];
    }

    return betweenComponents;
}

+ (id)timingFunctionWithConstant:(CGFloat)constant bounce:(CGFloat)bounce sensitivity:(CGFloat)sensitivity {
    XNDecayTimingFunction *timingFunction = [self timingFunction];
    [timingFunction setBounce:bounce];
    [timingFunction setConstant:constant];
    [timingFunction setSensitivity:sensitivity];
    return timingFunction;
}

+ (id)timingFunctionWithConstant:(CGFloat)constant bounce:(CGFloat)bounce {
    return [self timingFunctionWithConstant:constant bounce:bounce sensitivity:kXNDecayTimingFunctionDefaultSensitivity];
}

+ (id)timingFunctionWithConstant:(CGFloat)constant sensitivity:(CGFloat)sensitivity {
    return [self timingFunctionWithConstant:constant bounce:kXNDecayTimingFunctionDefaultBounce sensitivity:sensitivity];
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
        _constant = kXNDecayTimingFunctionDefaultConstant;
        _bounce = kXNDecayTimingFunctionDefaultBounce;
        _sensitivity = kXNDecayTimingFunctionDefaultSensitivity;
    }

    return self;
}

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed velocity:(CGFloat)velocity from:(CGFloat)from to:(CGFloat)to complete:(BOOL *)outComplete {
    [super simulateIndex:i elapsed:elapsed velocity:velocity from:from to:to complete:outComplete];

    CGFloat c = _constant;
    CGFloat b = _bounce;
    
    CGFloat s = _sensitivity / kXNDecayTimingFunctionTemporalSensitivity;
    CGFloat v0 = velocity / kXNDecayTimingFunctionTemporalSensitivity;
    CGFloat t = elapsed * kXNDecayTimingFunctionTemporalSensitivity;

    NSNumber *insideValue = [_insideComponents objectAtIndex:i];
    BOOL outside = ![insideValue boolValue];

    CGFloat tSwitch = 0;
    CGFloat xSwitch = 0;

    if (outside) {
        tSwitch = 0;
        xSwitch = from;
    } else {
        //from + c * v0 * (1 - powf(c, t)) / (1 - c) = to
        //(to - from) / (c * v0) = (1 - powf(c, t)) / (1 - c)
        //(1 - c) * (to - from) / (c * v0) = 1 - powf(c, t)
        //-((1 - c) * (to - from) / (c * v0) - 1) = powf(c, t)
        tSwitch = logf(-((1 - c) * fabs(to - from) / (c * fabs(v0)) - 1)) / logf(c);
        xSwitch = XNDecayTimingFunctionSimpleDistanceAtTime(c, tSwitch, v0, from);
    }

    BOOL switched = t > tSwitch;

    CGFloat v = 0;
    CGFloat x = 0;

    if (!switched) {
        v = XNDecayTimingFunctionSimpleVelocityAtTime(c, t, v0);
        x = XNDecayTimingFunctionSimpleDistanceAtTime(c, t, v0, from);
    } else {
        t = t - tSwitch;
        v = XNDecayTimingFunctionBouncingVelocityAtTime(c, b, t, v0);
        x = XNDecayTimingFunctionBouncingDistanceAtTime(c, b, t, v0, xSwitch, to);
    }

    if (fabs(v) <= s && fabs(x - to) <= _sensitivity) {
        *outComplete = YES;
        return to;
    } else {
        *outComplete = NO;
        return x;
    }
}

@end
