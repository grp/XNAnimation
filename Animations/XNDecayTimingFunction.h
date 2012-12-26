//
//  XNDecayTimingFunction.h
//  Animations
//
//  Created by Grant Paul on 11/28/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNTimingFunction.h"

@interface XNDecayTimingFunction : XNTimingFunction

@property (nonatomic, assign) CGFloat constant;
@property (nonatomic, assign) CGFloat sensitivity;

+ (id)toValueFromValue:(id)from forVelocity:(id)velocity withConstant:(CGFloat)constant;
+ (id)toValueFromValue:(id)from forVelocity:(id)velocity withConstant:(CGFloat)constant sensitivity:(CGFloat)sensitivity;

+ (id)timingFunctionWithConstant:(CGFloat)constant;
+ (id)timingFunctionWithConstant:(CGFloat)constant sensitivity:(CGFloat)sensitivity;

@end

