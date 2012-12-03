//
//  NSObject+XNAnimation.m
//  Animations
//
//  Created by Grant Paul on 12/1/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import "NSObject+XNAnimation.h"

// To track object deallocations with categories, a sentinel is added as an
// associated object, which can be automatically deallocated on release. That
// gives us enough of a hook to clear out other remaining references.
static NSString *XNAnimationLinkSentinelKey = @"XNAnimationLinkSentinelKey";

@interface XNAnimationLinkSentinel : NSObject

@property (nonatomic, assign) id object;

- (id)initWithObject:(id)object;

@end

@implementation XNAnimationLinkSentinel {
    NSValue *_value;
}

- (id)object {
    return [_value nonretainedObjectValue];
}

- (void)setObject:(id)object {
    [_value release];
    _value = [[NSValue valueWithNonretainedObject:_value] retain];
}

- (id)initWithObject:(id)object {
    if ((self = [super init])) {
        [self setObject:object];
    }

    return self;
}

- (void)dealloc {
    id object = [_value nonretainedObjectValue];
    [[XNAnimationLink sharedInstance] removeAnimationsFromObject:object];

    [_value release];
    [super dealloc];
}

@end

@implementation NSObject (XNAnimation)

- (void)addXNAnimation:(XNAnimation *)animation {
    if (objc_getAssociatedObject(self, &XNAnimationLinkSentinelKey) == nil) {
        XNAnimationLinkSentinel *sentinel = [[XNAnimationLinkSentinel alloc] initWithObject:self];
        objc_setAssociatedObject(self, &XNAnimationLinkSentinelKey, sentinel, OBJC_ASSOCIATION_RETAIN);
        [sentinel release];
    }

    [[XNAnimationLink sharedInstance] addAnimation:animation toObject:self];
}

- (BOOL)hasXNAnimation:(XNAnimation *)animation {
    return [[XNAnimationLink sharedInstance] animation:animation isAttachedToObject:self];
}

- (void)removeXNAnimation:(XNAnimation *)animation {
    [[XNAnimationLink sharedInstance] removeAnimation:animation fromObject:self];
}

- (BOOL)hasXNAnimations {
    return [[XNAnimationLink sharedInstance] objectHasAnimations:self];
}

- (void)removeAllXNAnimations {
    [[XNAnimationLink sharedInstance] removeAnimationsFromObject:self];
}

@end

