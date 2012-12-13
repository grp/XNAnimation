//
//  XNAnimationLink.m
//  Animations
//
//  Created by Grant Paul on 11/23/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "XNAnimation.h"
#import "XNAnimationLink.h"

@implementation XNAnimationLink {
    CADisplayLink *_displayLink;

    NSMutableDictionary *_activeAnimations;

    NSTimeInterval _then;
}

+ (id)sharedInstance {
    static XNAnimationLink *sharedAnimationLink = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAnimationLink = [[XNAnimationLink alloc] init];
    });

    return sharedAnimationLink;
}

- (id)init {
    if ((self = [super init])) {
        _displayLink = [[CADisplayLink displayLinkWithTarget:self selector:@selector(frameFromDisplayLink:)] retain];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

        _activeAnimations = [[NSMutableDictionary alloc] init];

        _then = [NSDate timeIntervalSinceReferenceDate];
    }

    return self;
}

- (void)addAnimation:(XNAnimation *)animation toObject:(id)object {
    NSValue *value = [NSValue valueWithNonretainedObject:object];

    if ([_activeAnimations objectForKey:value] == nil) {
        [_activeAnimations setObject:[NSMutableSet set] forKey:value];
    }

    NSMutableSet *animations = [_activeAnimations objectForKey:value];
    [animations addObject:animation];

    [animation beginWithTarget:object];
}

- (BOOL)animation:(XNAnimation *)animation isAttachedToObject:(id)object {
    NSValue *value = [NSValue valueWithNonretainedObject:object];

    NSMutableSet *animations = [_activeAnimations objectForKey:value];
    BOOL contains = [animations containsObject:animation];

    return contains;
}

- (void)removeAnimation:(XNAnimation *)animation fromObject:(id)object {
    NSValue *value = [NSValue valueWithNonretainedObject:object];

    NSMutableSet *animations = [_activeAnimations objectForKey:value];
    [animations removeObject:animation];

    if ([animation active]) {
        [animation end];
    }

    if ([animations count] == 0) {
        [_activeAnimations removeObjectForKey:value];
    }
}

- (BOOL)objectHasAnimations:(id)object {
    NSValue *value = [NSValue valueWithNonretainedObject:object];

    NSMutableSet *animations = [_activeAnimations objectForKey:value];
    BOOL has = (animations != nil);

    return has;
}

- (void)removeAnimationsFromObject:(id)object {
    NSValue *value = [NSValue valueWithNonretainedObject:object];

    // Copy to allow mutation (and, in fact, deallocation) while iterating.
    NSSet *animations = [[_activeAnimations objectForKey:value] copy];
    
    for (XNAnimation *animation in animations) {
        [self removeAnimation:animation fromObject:object];
    }

    [animations release];
}

- (void)frameFromDisplayLink:(CADisplayLink *)displayLink {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval frame = now - _then;
    _then = now;

    NSMutableDictionary *completedAnimations = [NSMutableDictionary dictionary];

    for (NSValue *value in _activeAnimations) {
        NSSet *animations = [_activeAnimations objectForKey:value];
        
        for (XNAnimation *animation in animations) {
            [animation simulateWithTimeInterval:frame];

            if ([animation completed] && [animation isRemovedOnCompletion]) {
                if ([completedAnimations objectForKey:value] == nil) {
                    [completedAnimations setObject:[NSMutableSet set] forKey:value];
                }

                NSMutableSet *completed = [completedAnimations objectForKey:value];
                [completed addObject:animation];
            }
        }
    }

    for (NSValue *value in completedAnimations) {
        NSSet *completed = [completedAnimations objectForKey:value];

        for (XNAnimation *animation in completed) {
            [self removeAnimation:animation fromObject:[value nonretainedObjectValue]];
        }
    }
}

@end
