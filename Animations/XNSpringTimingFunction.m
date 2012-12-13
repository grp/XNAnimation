//
//  XNSpringTimingFunction.m
//  Animations
//
//  Created by Grant Paul on 11/24/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNSpringTimingFunction.h"

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

- (id)init {
    if ((self = [super init])) {
        _k = 273;
        _b = 20;
        _m = 1;
    }

    return self;
}

- (CGFloat)simulateWithTimeInterval:(NSTimeInterval)dt velocity:(CGFloat)velocity from:(CGFloat)from to:(CGFloat)to complete:(BOOL *)outComplete {
    [super simulateWithTimeInterval:dt velocity:velocity from:from to:to complete:outComplete];

    CGFloat t = [self elapsed];

    // The equation below is springing around zero, so invert it.
    CGFloat xF = (to - from);

    CGFloat x0 = xF;
    CGFloat v0 = -velocity;
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

    x = from + (xF - x);

    if (fabs(x - to) <= 0.01) {
        *outComplete = YES;
        return to;
    } else {
        *outComplete = NO;
        return x;
    }
}

@end

/*typedef struct {
    CGFloat x; // position
    CGFloat v; // velocity
} State;

typedef struct {
    CGFloat dx; // derivative of position: velocity
    CGFloat dv; // derivative of velocity: acceleration
} Derivative;

- (CGFloat)accelerationAtState:(State)s {
    return ((-_k * (s.x - 1.0f)) - (_b * s.v)) / _m;
}

- (Derivative)evaluateAtState:(State)initial timeDelta:(NSTimeInterval)dt derivative:(Derivative)d {
    State state;
    state.x = initial.x + d.dx * dt;
    state.v = initial.v + d.dv * dt;

    Derivative output;
    output.dx = state.v;
    output.dv = [self accelerationAtState:state];
    return output;
}

- (State)integrateWithTimeDelta:(NSTimeInterval)dt {
    Derivative _ = { 0 };
    Derivative a = [self evaluateAtState:_s timeDelta:0.0 derivative:_];
    Derivative b = [self evaluateAtState:_s timeDelta:(dt * 0.5f) derivative:a];
    Derivative c = [self evaluateAtState:_s timeDelta:(dt * 0.5f) derivative:b];
    Derivative d = [self evaluateAtState:_s timeDelta:dt derivative:c];

    CGFloat dxdt = 1.0f / 6.0f * (a.dx + 2.0f * (b.dx + c.dx) + d.dx);
    CGFloat dvdt = 1.0f / 6.0f * (a.dv + 2.0f * (b.dv + c.dv) + d.dv);

    State state = _s;
    state.x = state.x + dxdt * dt;
    state.v = state.v + dvdt * dt;
    return state;
}

- (void)reset {
    [super reset];
    
    _s.x = 0;
    _s.v = 0;
}

- (CGFloat)simulateWithTimeInterval:(NSTimeInterval)dt complete:(BOOL *)outComplete {
    CGFloat px = _s.x;
    
    _s = [self integrateWithTimeDelta:dt];
    [super simulateWithTimeInterval:dt complete:outComplete];

    CGFloat dx = fabs(px - _s.x);
    if (dx <= _sensitivity) {
        *outComplete = YES;
        return 1.0;
    } else {
        *outComplete = NO;
        return _s.x;
    }
}*/
