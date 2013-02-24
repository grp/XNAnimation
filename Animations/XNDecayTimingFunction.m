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
const static CGFloat kXNDecayTimingFunctionDefaultSensitivity = 0.001f;

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

// The basic scroll view algorithm, each frame:
//
// v = v * c                 -- constant friciton
// x = x + v                 -- v = dx/dt
// if outside:
//   x = x - d * (1 - b)     -- the magic: move back
//   v = v * b               -- slow down faster
//
// d: distance outside scroll view
// c: scrolling constant; 0.998
// b: bounce constant; 0.99
//
// Apple implements this strangely. Rather than taking an integral of the above,
// they use a summation over every millisecond. To reproduce the same behavior
// and to allow for use of identical scrolling and bounce coefficients, the same
// strange features are emulated here, with the millisecond conversion factor
// stored in kXNDecayTimingFunctionTemporalSensitivity and the simplification of
// the summation present in the following functions.

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

    CGFloat v0 = velocity / kXNDecayTimingFunctionTemporalSensitivity;

    // Solve for time when velocity = sensitivity.
    CGFloat t = logf(sensitivity / fabs(v0)) / logf(constant);
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

+ (id)insideValueFromValue:(id)fromValue toValue:(id)toValue minimumValue:(id)minimumValue maximumValue:(id)maximumValue {
    XNKeyValueExtractor *kve = [[XNKeyValueExtractor alloc] init];
    NSArray *minimumComponents = [kve componentsForObject:minimumValue];
    NSArray *maximumComponents = [kve componentsForObject:maximumValue];
    NSArray *fromComponents = [kve componentsForObject:fromValue];
    NSArray *toComponents = [kve componentsForObject:toValue];
    [kve release];

    NSMutableArray *betweenComponents = [NSMutableArray array];

    for (NSUInteger i = 0; i < [fromComponents count]; i++) {
        CGFloat min = [[minimumComponents objectAtIndex:i] floatValue];
        CGFloat max = [[maximumComponents objectAtIndex:i] floatValue];
        CGFloat from = [[fromComponents objectAtIndex:i] floatValue];
        CGFloat to = [[toComponents objectAtIndex:i] floatValue];

        BOOL leftOutside = (from <= min && to <= min);
        BOOL rightOutside = (from >= max && to >= max);

        NSValue *betweenValue = [NSNumber numberWithBool:(!rightOutside && !leftOutside)];
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

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed velocity:(CGFloat)velocity complete:(BOOL *)outComplete {
    [super simulateIndex:i elapsed:elapsed velocity:velocity complete:outComplete];

    CGFloat c = _constant;
    CGFloat b = _bounce;
    
    CGFloat v0 = velocity / kXNDecayTimingFunctionTemporalSensitivity;
    CGFloat t = elapsed * kXNDecayTimingFunctionTemporalSensitivity;

    NSNumber *insideValue = [_insideComponents objectAtIndex:i];
    BOOL outside = ![insideValue boolValue];

    CGFloat tSwitch = 0;
    CGFloat xSwitch = 0;

    if (outside) {
        tSwitch = 0;
        xSwitch = 0;
    } else {
        // Solve for time when distance equals 1.0.
        // c * v0 * (1 - powf(c, t)) / (1 - c) = 1.0
        // 1.0 / (c * v0) = (1 - powf(c, t)) / (1 - c)
        // (1 - c) / (c * v0) = 1 - powf(c, t)
        // -((1 - c) / (c * v0) - 1) = powf(c, t)
        // t = logf(-((1 - c) / (c * fabs(v0)) - 1)) / logf(c)
        tSwitch = logf(-((1 - c) / (c * fabs(v0)) - 1)) / logf(c);

        if (isnan(tSwitch)) {
            // Is this the right thing to do here?
            tSwitch = CGFLOAT_MAX;
        }
        
        xSwitch = XNDecayTimingFunctionSimpleDistanceAtTime(c, tSwitch, v0, 0.0);
    }

    CGFloat v = 0;
    CGFloat x = 0;

    if (t < tSwitch) {
        v = XNDecayTimingFunctionSimpleVelocityAtTime(c, t, v0);
        x = XNDecayTimingFunctionSimpleDistanceAtTime(c, t, v0, 0.0);
    } else {
        CGFloat vSwitch = XNDecayTimingFunctionSimpleVelocityAtTime(c, tSwitch, v0);
        CGFloat tAfterSwitch = t - tSwitch;
        
        v = XNDecayTimingFunctionBouncingVelocityAtTime(c, b, tAfterSwitch, vSwitch);
        x = XNDecayTimingFunctionBouncingDistanceAtTime(c, b, tAfterSwitch, vSwitch, xSwitch, 1.0);
    }

    if (fabs(v) <= _sensitivity && fabs(x - 1.0) < _sensitivity) {
        *outComplete = YES;
        return 1.0;
    } else {
        *outComplete = NO;
        return x;
    }
}

@end
