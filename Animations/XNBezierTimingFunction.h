//
//  XNBezierTimingFunction.h
//  Animations
//
//  Created by Grant Paul on 11/25/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNTimingFunction.h"

@interface XNBezierTimingFunction : XNTimingFunction

+ (NSArray *)controlPointsEaseIn;
+ (NSArray *)controlPointsEaseOut;
+ (NSArray *)controlPointsEaseInOut;
+ (id)timingFunctionWithControlPoints:(NSArray *)points;

@property (nonatomic, copy) NSArray *controlPoints;

@end
