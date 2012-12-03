//
//  XNSpringTimingFunction.h
//  Animations
//
//  Created by Grant Paul on 11/24/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNTimingFunction.h"

@interface XNSpringTimingFunction : XNTimingFunction

@property (nonatomic, assign) CGFloat tension;
@property (nonatomic, assign) CGFloat damping;
@property (nonatomic, assign) CGFloat mass;

+ (id)timingFunctionWithTension:(CGFloat)tension damping:(CGFloat)damping mass:(CGFloat)mass;

@end
