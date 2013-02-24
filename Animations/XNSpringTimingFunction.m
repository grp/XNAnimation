//
//  XNSpringTimingFunction.m
//  Animations
//
//  Created by Grant Paul on 11/24/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNSpringTimingFunction.h"

const static CGFloat kXNSpringTimingFunctionDefaultTension = 273.0f;
const static CGFloat kXNSpringTimingFunctionDefaultDamping = 20.0f;
const static CGFloat kXNSpringTimingFunctionDefaultMass = 1.0f;

@implementation XNSpringTimingFunction {
    CGFloat _k; // tension
    CGFloat _b; // damping
    CGFloat _m; // mass
}

@synthesize tension = _k;
@synthesize damping = _b;
@synthesize mass = _m;

+ (id)timingFunctionWithTension:(CGFloat)tension damping:(CGFloat)damping mass:(CGFloat)mass {
    XNSpringTimingFunction *spring = [[[self alloc] init] autorelease];
    [spring setTension:tension];
    [spring setDamping:damping];
    [spring setMass:mass];
    return spring;
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [super copyWithZone:zone];
    [copy setTension:[self tension]];
    [copy setDamping:[self damping]];
    [copy setMass:[self mass]];
    return copy;
}

- (id)init {
    if ((self = [super init])) {
        _k = kXNSpringTimingFunctionDefaultTension;
        _b = kXNSpringTimingFunctionDefaultDamping;
        _m = kXNSpringTimingFunctionDefaultMass;
    }

    return self;
}

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed velocity:(CGFloat)velocity complete:(BOOL *)outComplete {
    [super simulateIndex:i elapsed:elapsed velocity:velocity complete:outComplete];

    CGFloat v0 = -velocity;
    CGFloat x0 = 1.0;

    CGFloat t = elapsed;

    CGFloat w0 = sqrtf(_k / _m);

    CGFloat zeta = _b / (2 * sqrtf(_m * _k));
    CGFloat x = 0;

    if (zeta < 1.0f) {
        CGFloat wD = w0 * sqrtf(1 - zeta * zeta);

        CGFloat A = x0;
        CGFloat B = (zeta * w0 * x0 + v0) / wD;

        x = powf(M_E, -zeta * w0 * t) * (A * cos(wD * t) + B * sin(wD * t));
    } else if (zeta == 1.0f) {
        CGFloat A = x0;
        CGFloat B = v0 * w0 * x0;

        x = powf(M_E, -w0 * t) * (A + B * t);
    } else if (zeta > 1.0f) {
        CGFloat gP = (-_b + sqrtf(powf(_b, 2) - 4 * w0)) / 2;
        CGFloat gM = (-_b - sqrtf(powf(_b, 2) - 4 * w0)) / 2;

        CGFloat A = x0 - (gM * x0 - v0) / (gM - gP);
        CGFloat B = (gM * x0 - v0) / (gM - gP);

        x = A * powf(M_E, gM * t) + B * powf(M_E, gP * t);
    }

    x = 1.0 - x;

    if (fabs(x - 1.0) <= 0.001) {
        *outComplete = YES;
        return 1.0;
    } else {
        *outComplete = NO;
        return x;
    }
}

@end
