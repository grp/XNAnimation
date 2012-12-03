//
//  XNAnimationLink.h
//  Animations
//
//  Created by Grant Paul on 11/23/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

@class XNAnimation;

@interface XNAnimationLink : NSObject

+ (id)sharedInstance;

- (void)addAnimation:(XNAnimation *)animation toObject:(id)object;
- (BOOL)animation:(XNAnimation *)animation isAttachedToObject:(id)object;
- (void)removeAnimation:(XNAnimation *)animation fromObject:(id)object;

- (BOOL)objectHasAnimations:(id)object;
- (void)removeAnimationsFromObject:(id)object;

@end
