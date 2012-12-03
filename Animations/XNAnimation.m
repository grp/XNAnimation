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

    // State-dependent properties.
    id _target;
    BOOL _completed;
    id<XNAnimationDelegate> _delegate;

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

#pragma mark - Lifecycle

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

static NSTimeInterval t = 0;

- (void)beginWithTarget:(id)target {
    _completed = NO;
    _target = target;

    if (_toValue == nil) {
        [NSException raise:@"XNAnimationInvalidParameterException" format:@"you must specify a toValue"];
    }

    if (_velocity != nil && !isnan(_duration)) {
        [NSException raise:@"XNAnimationInvalidParameterException" format:@"you cannot specify both a duration and a velocity"];
    }

    NSValue *fromValue = _fromValue;
    if (fromValue == nil) {
        fromValue = [[_extractor object:_target valueForKeyPath:_keyPath] copy];
    }

    _fromComponents = [[_extractor componentsForObject:fromValue] retain];
    _toComponents = [[_extractor componentsForObject:_toValue] retain];

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

    [_delegate animationStarted:self];
    t = [NSDate timeIntervalSinceReferenceDate];
}

- (void)simulateWithTimeInterval:(NSTimeInterval)dt {
    NSArray *positions = [_timingFunction simulateWithTimeInterval:dt durations:_durations velocities:_velocities fromComponents:_fromComponents toComponents:_toComponents complete:&_completed];

    id value = [_extractor objectFromComponents:positions templateObject:_toValue];
    [_extractor object:_target setValue:value forKeyPath:_keyPath];

    [_delegate animationUpdated:self];
}

- (void)reset {
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
