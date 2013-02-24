//
//  XNAnimation.m
//  Animations
//
//  Created by Grant Paul on 11/23/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNAnimation.h"

#import "XNKeyValueExtractor.h"
#import "XNBezierTimingFunction.h"

const NSTimeInterval kXNAnimationDefaultDuration = 1.0;

@implementation XNAnimation {
    XNKeyValueExtractor *_extractor;

    // Configuration properties.
    NSString *_keyPath;
    id _fromValue;
    id _toValue;
    NSTimeInterval _duration;
    id _velocity;
    XNTimingFunction *_timingFunction;
    BOOL _removedOnCompletion;
    id<XNAnimationDelegate> _delegate;
    BOOL _delegateWantsProgress;

    // State-dependent properties.
    id _target;
    BOOL _completed;
    NSTimeInterval _elapsed;

    NSArray *_durations;
    NSArray *_velocities;
    NSArray *_toComponents;
    NSArray *_fromComponents;
}

#pragma mark - Properties

@synthesize keyPath = _keyPath;
@synthesize removedOnCompletion = _removedOnCompletion;
@synthesize completed = _completed;
@synthesize delegate = _delegate;

@synthesize fromValue = _fromValue;
@synthesize toValue = _toValue;

@synthesize timingFunction = _timingFunction;
@synthesize duration = _duration;
@synthesize velocity = _velocity;

- (void)setFromValue:(id)fromValue {
    [_fromValue release];

    if ([fromValue respondsToSelector:@selector(copyWithZone:)]) {
        _fromValue = [fromValue copy];
    } else {
        _fromValue = [fromValue retain];
    }

    [_fromComponents release];
    _fromComponents = nil;
}

- (void)setToValue:(id)toValue {
    [_toValue release];
    
    if ([toValue respondsToSelector:@selector(copyWithZone:)]) {
        _toValue = [toValue copy];
    } else {
        _toValue = [toValue retain];
    }

    [_toComponents release];
    _toComponents = nil;
}

- (void)setDuration:(NSTimeInterval)duration {
    _duration = duration;

    [_durations release];
    _durations = nil;
}

- (void)setVelocity:(id)velocity {
    [_velocity release];

    if ([velocity respondsToSelector:@selector(copyWithZone:)]) {
        _velocity = [velocity copy];
    } else {
        _velocity = [velocity retain];
    }

    [_velocities release];
    _velocities = nil;
}

#pragma mark - Lifecycle

- (void)setDelegate:(id<XNAnimationDelegate>)delegate {
    _delegate = delegate;

    _delegateWantsProgress = [_delegate respondsToSelector:@selector(animationUpdated:)];
}

+ (id)animation {
    XNAnimation *animation = [[[self alloc] init] autorelease];
    return animation;
}

+ (id)animationWithKeyPath:(NSString *)keyPath {
    XNAnimation *animation = [[[self alloc] initWithKeyPath:keyPath] autorelease];
    return animation;
}

+ (id)animationWithKeyPath:(NSString *)keyPath timingFunction:(XNTimingFunction *)timingFunction toValue:(NSValue *)value duration:(NSTimeInterval)duration {
    XNAnimation *animation = [self animationWithKeyPath:keyPath];
    [animation setTimingFunction:timingFunction];
    [animation setToValue:value];
    [animation setDuration:duration];
    return animation;
}

+ (id)animationWithKeyPath:(NSString *)keyPath timingFunction:(XNTimingFunction *)timingFunction toValue:(NSValue *)value velocity:(NSValue *)velocity {
    XNAnimation *animation = [self animationWithKeyPath:keyPath];
    [animation setTimingFunction:timingFunction];
    [animation setToValue:value];
    [animation setVelocity:velocity];
    return animation;
}

- (id)initWithKeyPath:(NSString *)keyPath {
    if ((self = [self init])) {
        [self setKeyPath:keyPath];
    }

    return self;
}

- (id)init {
    if ((self = [super init])) {
        _duration = NAN;
        _removedOnCompletion = YES;
        _extractor = [[XNKeyValueExtractor alloc] init];
        _timingFunction = [[XNBezierTimingFunction timingFunctionWithControlPoints:[XNBezierTimingFunction controlPointsEaseInOut]] retain];
    }

    return self;
}

- (void)dealloc {
    [self reset];
    
    [_extractor release];
    [_timingFunction release];

    [_toValue release];
    _toValue = nil;
    [_fromValue release];
    _fromValue = nil;
    [_velocity release];
    _velocity = nil;
    _duration = NAN;

    [super dealloc];
}

#pragma mark - Animation

- (void)extractUpdatedParameters {
    if (_toComponents == nil) {
        if (_toValue == nil) {
            [NSException raise:@"XNAnimationInvalidParameterException" format:@"you must specify a toValue"];
        }
    
        _toComponents = [[_extractor componentsForObject:_toValue] retain];
    }

    if (_fromComponents == nil) {
        NSValue *fromValue = _fromValue;
        if (fromValue == nil) {
            fromValue = [_extractor object:_target valueForKeyPath:_keyPath];

            if ([fromValue respondsToSelector:@selector(copyWithZone:)]) {
                fromValue = [fromValue copy];
            } else {
                fromValue = [fromValue retain];
            }
        }

        _fromComponents = [[_extractor componentsForObject:fromValue] retain];
    }

    if (_velocities == nil && _durations == nil) {
        if (_velocity != nil && !isnan(_duration)) {
            [NSException raise:@"XNAnimationInvalidParameterException" format:@"you cannot specify both a duration and a velocity"];
        }

        if (_velocity != nil) {
            NSArray *componentValues = [_extractor componentsForObject:_velocity];
            _velocities = [componentValues retain];
        } else if (!isnan(_duration)) {
            NSTimeInterval effectiveDuration = _duration;

            if (isnan(effectiveDuration)) {
                effectiveDuration = kXNAnimationDefaultDuration;
            }

            NSMutableArray *durations = [NSMutableArray array];

            for (NSUInteger i = 0; i < [_toComponents count]; i++) {
                NSNumber *number = [NSNumber numberWithDouble:effectiveDuration];
                [durations addObject:number];
            }

            _durations = [durations retain];
        }
    }
}

- (void)beginWithTarget:(id)target {
    _completed = NO;
    _target = target;

    [self extractUpdatedParameters];

    if ([_delegate respondsToSelector:@selector(animationStarted:)]) {
        [_delegate animationStarted:self];
    }
}

- (void)simulateWithTimeInterval:(NSTimeInterval)dt {
    _elapsed += dt;

    [self extractUpdatedParameters];

    NSArray *positions = [_timingFunction simulateWithTimeInterval:dt elapsed:_elapsed durations:_durations velocities:_velocities fromComponents:_fromComponents toComponents:_toComponents complete:&_completed];

    id value = [_extractor objectFromComponents:positions templateObject:_toValue];
    [_extractor object:_target setValue:value forKeyPath:_keyPath];

    if (_delegateWantsProgress) {
        [_delegate animationUpdated:self];
    }
}

- (void)end {
    if ([_delegate respondsToSelector:@selector(animationStopped:)]) {
        [_delegate animationStopped:self];
    }

    [self reset];
}

- (BOOL)active {
    return _target != nil;
}

- (void)reset {
    _elapsed = 0;
    _target = nil;

    [_fromComponents release];
    _fromComponents = nil;
    [_toComponents release];
    _toComponents = nil;
    [_durations release];
    _durations = nil;
    [_velocities release];
    _velocities = nil;
}

@end
