//
//  XNTimingFunction.h
//  Animations
//
//  Created by Grant Paul on 11/24/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

@interface XNTimingFunction : NSObject

+ (id)timingFunction;

- (NSArray *)simulateWithTimeInterval:(NSTimeInterval)dt durations:(NSArray *)durations velocities:(NSArray *)velocities fromComponents:(NSArray *)fromComponents toComponents:(NSArray *)toComponents complete:(BOOL *)outComplete;
- (void)reset; // FIXME: reset elapsed

// Subclasses
@property (nonatomic, readonly) NSTimeInterval elapsed;
- (CGFloat)simulateWithTimeInterval:(NSTimeInterval)dt duration:(CGFloat)duration from:(CGFloat)from to:(CGFloat)to complete:(BOOL *)outComplete;
- (CGFloat)simulateWithTimeInterval:(NSTimeInterval)dt velocity:(CGFloat)velocity from:(CGFloat)from to:(CGFloat)to complete:(BOOL *)outComplete;

@end
