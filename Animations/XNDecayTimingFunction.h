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
@property (nonatomic, assign) CGFloat bounce;
@property (nonatomic, assign) CGFloat sensitivity;

@property (nonatomic, retain) id insideValue;

// The value returned is of the same type as the from value passed in.
+ (id)toValueFromValue:(id)from forVelocity:(id)velocity withConstant:(CGFloat)constant;
+ (id)toValueFromValue:(id)from forVelocity:(id)velocity withConstant:(CGFloat)constant sensitivity:(CGFloat)sensitivity;

// The return value of this method is only valid for assigning to insideValue.
+ (id)insideValueFromValue:(id)fromValue toValue:(id)toValue minimumValue:(id)minimumValue maximumValue:(id)maximumValue;

+ (id)timingFunctionWithConstant:(CGFloat)constant;
+ (id)timingFunctionWithConstant:(CGFloat)constant bounce:(CGFloat)bounce;
+ (id)timingFunctionWithConstant:(CGFloat)constant sensitivity:(CGFloat)sensitivity;
+ (id)timingFunctionWithConstant:(CGFloat)constant bounce:(CGFloat)bounce sensitivity:(CGFloat)sensitivity;

@end

