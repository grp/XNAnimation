//
//  XNTimingFunction.h
//  Animations
//
//  Created by Grant Paul on 11/24/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

@interface XNTimingFunction : NSObject <NSCopying>

+ (id)timingFunction;

// Private
- (NSArray *)simulateWithTimeInterval:(NSTimeInterval)dt elapsed:(NSTimeInterval)elapsed durations:(NSArray *)durations velocities:(NSArray *)velocities fromComponents:(NSArray *)fromComponents toComponents:(NSArray *)toComponents complete:(BOOL *)outComplete;

// Subclasses
- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed duration:(CGFloat)duration complete:(BOOL *)outComplete;
- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed velocity:(CGFloat)velocity complete:(BOOL *)outComplete;

@end
