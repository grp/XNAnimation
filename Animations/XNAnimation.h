//
//  XNAnimation.h
//  Animations
//
//  Created by Grant Paul on 11/23/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

@class XNTimingFunction;
@protocol XNAnimationDelegate;

@interface XNAnimation : NSObject

+ (id)animation;
+ (id)animationWithKeyPath:(NSString *)keyPath;
+ (id)animationWithKeyPath:(NSString *)keyPath timingFunction:(XNTimingFunction *)timingFunction toValue:(NSValue *)value duration:(NSTimeInterval)duration;
+ (id)animationWithKeyPath:(NSString *)keyPath timingFunction:(XNTimingFunction *)timingFunction toValue:(NSValue *)value velocity:(NSValue *)velocity;

- (id)initWithKeyPath:(NSString *)keyPath;

@property (nonatomic, copy) NSString *keyPath; // required
@property (nonatomic, retain) XNTimingFunction *timingFunction; // required, default bezier

@property (nonatomic, copy) id fromValue; // optional, default current state

// required: set exactly two of the following three properites
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, copy) id velocity;
@property (nonatomic, copy) id toValue;

@property (nonatomic, assign, getter=isRemovedOnCompletion) BOOL removedOnCompletion; // default YES
@property (nonatomic, assign) id<XNAnimationDelegate> delegate; // optional, default nil

@property (nonatomic, assign, readonly) BOOL completed; // reset to NO when started

@end

@protocol XNAnimationDelegate <NSObject>

@optional
- (void)animationStarted:(XNAnimation *)animation;
- (void)animationUpdated:(XNAnimation *)animation;
- (void)animationStopped:(XNAnimation *)animation;

@end

@interface XNAnimation (Private)

- (BOOL)active;
- (void)beginWithTarget:(id)target;
- (void)simulateWithTimeInterval:(NSTimeInterval)dt;
- (void)end;
- (void)reset;

@end
