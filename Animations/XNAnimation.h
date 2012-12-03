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

@property (nonatomic, assign) NSTimeInterval duration; // required, cannot set velocity
@property (nonatomic, copy) id velocity; // required, cannot set duration

@property (nonatomic, copy) id fromValue; // optional, default current state
@property (nonatomic, copy) id toValue; // required

@property (nonatomic, assign, getter=isRemovedOnCompletion) BOOL removedOnCompletion; // default YES
@property (nonatomic, assign) id<XNAnimationDelegate> delegate; // optional, default nil

@property (nonatomic, readonly) BOOL completed; // private, not what you think!

@end

@protocol XNAnimationDelegate <NSObject>

@optional
- (void)animationStarted:(XNAnimation *)animation;
- (void)animationUpdated:(XNAnimation *)animation;
- (void)animationStopped:(XNAnimation *)animation;

@end

@interface XNAnimation (Private)

- (void)beginWithTarget:(id)target;
- (void)simulateWithTimeInterval:(NSTimeInterval)dt;
- (void)reset;

@end
