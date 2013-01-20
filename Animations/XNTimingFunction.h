//
//  XNTimingFunction.h
//  Animations
//
//  Created by Grant Paul on 11/24/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

typedef NSArray XNTimingFunctionAdditional;

@interface XNTimingFunction : NSObject <NSCopying>

+ (id)timingFunction;

- (id)velocityValueFromValue:(id)fromValue toValue:(id)toValue   duration:(id)duration additional:(XNTimingFunctionAdditional *)additional;
- (id)durationValueFromValue:(id)fromValue toValue:(id)toValue   velocity:(id)velocity additional:(XNTimingFunctionAdditional *)additional;
- (id)toValueFromValue:(id)fromValue       duration:(id)duration velocity:(id)velocity additional:(XNTimingFunctionAdditional *)additional;

// Private
- (id)simulateWithElapsed:(NSTimeInterval)elapsed fromValue:(id)fromValue toValue:(id)toValue   duration:(id)duration additional:(XNTimingFunctionAdditional *)additional complete:(BOOL *)outComplete;
- (id)simulateWithElapsed:(NSTimeInterval)elapsed fromValue:(id)fromValue toValue:(id)toValue   velocity:(id)velocity additional:(XNTimingFunctionAdditional *)additional complete:(BOOL *)outComplete;
- (id)simulateWithElapsed:(NSTimeInterval)elapsed fromValue:(id)fromValue duration:(id)duration velocity:(id)velocity additional:(XNTimingFunctionAdditional *)additional complete:(BOOL *)outComplete;

// Subclasses
- (id)valueByEnumeratingValues:(NSArray *)values usingBlock:(id (^)(NSUInteger index, NSArray *values))block;

- (CGFloat)velocityIndex:(NSUInteger)i from:(CGFloat)from to:(CGFloat)to             duration:(CGFloat)duration additional:(id)additional;
- (CGFloat)durationIndex:(NSUInteger)i from:(CGFloat)from to:(CGFloat)to             velocity:(CGFloat)velocity additional:(id)additional;
- (CGFloat)toIndex:(NSUInteger)i       from:(CGFloat)from duration:(CGFloat)duration velocity:(CGFloat)velocity additional:(id)additional;

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed from:(CGFloat)from to:(CGFloat)to             duration:(CGFloat)duration additional:(id)additional complete:(BOOL *)outComplete;
- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed from:(CGFloat)from to:(CGFloat)to             velocity:(CGFloat)velocity additional:(id)additional complete:(BOOL *)outComplete;
- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed from:(CGFloat)from duration:(CGFloat)duration velocity:(CGFloat)velocity additional:(id)additional complete:(BOOL *)outComplete;

@end
