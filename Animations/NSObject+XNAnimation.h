//
//  NSObject+XNAnimation.h
//  Animations
//
//  Created by Grant Paul on 12/1/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNTimingFunction.h"
#import "XNLinearTimingFunction.h"
#import "XNBezierTimingFunction.h"
#import "XNDecayTimingFunction.h"
#import "XNSpringTimingFunction.h"

#import "XNKeyValueExtractor.h"
#import "NSObject+XNKeyValueExtractor.h"

#import "XNAnimation.h"
#import "XNAnimationLink.h"

// To avoid conflicts, "XNAnimation" is used instead of "Animation".
// Note: using this on multithreaded/non-main-thread objects is unwise.
@interface NSObject (XNAnimation)

- (void)addXNAnimation:(XNAnimation *)animation;
- (BOOL)hasXNAnimation:(XNAnimation *)animation;
- (void)removeXNAnimation:(XNAnimation *)animation;

- (BOOL)hasXNAnimations;
- (void)removeAllXNAnimations;

@end
