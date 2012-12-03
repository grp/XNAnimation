//
//  XNAppDelegate.m
//  Animations
//
//  Created by Grant Paul on 11/23/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "XNAppDelegate.h"
#import "XNKeyValueExtractor.h"

#import "NSObject+XNAnimation.h"

@interface CASpringAnimation : CABasicAnimation
@property (nonatomic, assign) CGFloat mass;
@property (nonatomic, assign) CGFloat stiffness;
@property (nonatomic, assign) CGFloat damping;
@property (nonatomic, assign) CGFloat velocity;
@end

@implementation XNAppDelegate {
    UISegmentedControl *s;
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

UIView *sb = nil;
CGPoint p;

UISlider *sdl;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    UIView *brick = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 150)];
    [brick setBackgroundColor:[UIColor blueColor]];
    [brick.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
    p = CGPointMake(self.window.bounds.size.width / 2, self.window.bounds.size.height / 3);
    [brick.layer setPosition:p];
    [self.window addSubview:brick];
    sb = brick;


    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [brick addGestureRecognizer:pan];
    [pan setDelegate:self];

    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [brick addGestureRecognizer:pinch];
    [pinch setDelegate:self];

    UIRotationGestureRecognizer *rot = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rot:)];
    [brick addGestureRecognizer:rot];
    [rot setDelegate:self];

    s = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Spring", @"Decay", @"Bezier", @"Linear", @"Appear", nil]];
    CGFloat h = 50;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) h = 30;
    [s setFrame:CGRectMake(10, self.window.bounds.size.height - 10 - h, self.window.bounds.size.width - 20, h)];
    [s setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) [s setSegmentedControlStyle:UISegmentedControlStyleBar];
    [s addTarget:self action:@selector(sch:) forControlEvents:UIControlEventValueChanged];
    [s setSelectedSegmentIndex:0];
    [self.window addSubview:s];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 50, self.window.bounds.size.width - 20, 50)];
    [label setText:@"Drag, pinch, and zoom."];
    [label setTextColor:[UIColor blackColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [self.window addSubview:label];

    sdl = [[UISlider alloc] initWithFrame:CGRectMake(10, self.window.bounds.size.height - 10 - h - 10 - 20, self.window.bounds.size.width - 20, 20)];
    [sdl setMinimumValue:0.0];
    [sdl setValue:0.01];
    [sdl setMaximumValue:0.2];
    [sdl setHidden:YES];
    [self.window addSubview:sdl];

    /*id a = [[XNKeyValueExtractor alloc] init];
    NSLog(@"native: %@", [sb.layer valueForKeyPath:@"transform.translation"]);
    NSLog(@"mine: %@", [a object:sb valueForKeyPath:@"transform.translation"]);
    [a object:sb setValue:[NSNumber numberWithFloat:2.0] forKeyPath:@"layer.transform.scale.x"];
    [a object:sb setValue:[NSNumber numberWithFloat:2.0] forKeyPath:@"transform.scale.x"];
    [a object:sb setValue:[NSNumber numberWithFloat:0.5] forKeyPath:@"layer.opacity"];
    [a object:sb setValue:[NSNumber numberWithFloat:0.5] forKeyPath:@"alpha"];*/

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 animations:^{
            [label setAlpha:0.0];
        } completion:^(BOOL f) {
            [label removeFromSuperview];
        }];
    });

    return YES;
}

- (void)sch:(UISegmentedControl *)sc {
    int i = [s selectedSegmentIndex];
    static int o = 0;

    [sdl setHidden:(i != 1)];
    
    o = i;
}

- (XNTimingFunction *)tf:(BOOL *)vel {
    int i = [s selectedSegmentIndex];
    if (i == 0) {
        *vel = YES;
        return [XNSpringTimingFunction timingFunctionWithTension:273 damping:23 mass:1.0];
    } else if (i == 1) {
        *vel = YES;
        return [XNDecayTimingFunction timingFunctionWithConstant:[sdl value]];
    } else if (i == 2) {
        *vel = NO;
        return [XNBezierTimingFunction timingFunctionWithControlPoints:[XNBezierTimingFunction controlPointsEaseInOut]];
    } else if (i == 3) {
        *vel = NO;
        return [XNLinearTimingFunction timingFunction];
    } else if (i == 4) {
        *vel = NO;
        return [XNTimingFunction timingFunction];
    }

    return nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)pan:(UIPanGestureRecognizer *)pan {
    UIView *brick = [pan view];


    if (pan.state == UIGestureRecognizerStateBegan || pan.state == UIGestureRecognizerStateChanged) {
        [brick removeAllXNAnimations];

        CGPoint f = [brick.layer position];
        f = [pan translationInView:self.window];
        [brick.layer setPosition:CGPointMake(f.x + p.x, f.y + p.y)];

        CGPoint tr = [pan translationInView:self.window];
        CGFloat p = (fabs(tr.x / (self.window.bounds.size.width / 4)) + fabs(tr.y / (self.window.bounds.size.height / 3))) / 2;
        UIColor *c = [UIColor colorWithRed:0 green:p blue:(1-p) alpha:1];
        [brick setBackgroundColor:c];
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateEnded) {
        CGPoint v = [pan velocityInView:self.window];

        {
            XNAnimation *a = [[XNAnimation alloc] initWithKeyPath:@"center"];

            BOOL vel;
            XNTimingFunction *tf = [self tf:&vel];
            [a setTimingFunction:tf];
            if (!vel) {
                [a setDuration:0.5f];
            } else {
                [a setVelocity:[NSValue valueWithCGPoint:v]];
            }

            if ([s selectedSegmentIndex] != 1) {
                [a setToValue:[NSValue valueWithCGPoint:p]];
            } else {
                id to = [XNDecayTimingFunction toValueFromValue:[brick valueForKeyPath:@"center"] forVelocity:[NSValue valueWithCGPoint:v] withConstant:[sdl value]];
                [a setToValue:to];
            }
            
            [brick addXNAnimation:a];
        }
        
        {
            XNAnimation *a = [[XNAnimation alloc] initWithKeyPath:@"backgroundColor"];

            BOOL vel;
            XNTimingFunction *tf = [self tf:&vel];
            [a setTimingFunction:tf];
            if (vel) {
                [a setVelocity:[UIColor clearColor]];
            } else {
                [a setDuration:0.5f];
            }

            [a setToValue:[UIColor blueColor]];
            
            [brick addXNAnimation:a];
        }
    }
}

- (void)pinch:(UIPinchGestureRecognizer *)pinch {
    UIView *brick = [pinch view];

    if (pinch.state == UIGestureRecognizerStateBegan || pinch.state == UIGestureRecognizerStateChanged) {
        [brick removeAllXNAnimations];

        CGFloat r = [pinch scale];
        NSNumber *n = [NSNumber numberWithFloat:r];
        [brick setValue:n forXNKeyPath:@"transform.scale"];
    } else if (pinch.state == UIGestureRecognizerStateEnded || pinch.state == UIGestureRecognizerStateEnded) {
        CGFloat v = [pinch velocity];

        XNAnimation *a = [[XNAnimation alloc] initWithKeyPath:@"transform.scale"];
        
        BOOL vel;
        XNTimingFunction *tf = [self tf:&vel];
        [a setTimingFunction:tf];
        if (!vel) {
            [a setDuration:0.5f];
        } else {
            [a setVelocity:[NSNumber numberWithFloat:v]];
        }

        [a setToValue:[NSNumber numberWithFloat:1]];
        [brick addXNAnimation:a];
    }
}

- (void)rot:(UIRotationGestureRecognizer *)rot {
    UIView *brick = [rot view];

    if (rot.state == UIGestureRecognizerStateBegan || rot.state == UIGestureRecognizerStateChanged) {
        [brick removeAllXNAnimations];

        CGFloat r = [rot rotation];
        NSNumber *n = [NSNumber numberWithFloat:r];
        [brick setValue:n forXNKeyPath:@"transform.rotation"];
    } else if (rot.state == UIGestureRecognizerStateEnded || rot.state == UIGestureRecognizerStateEnded) {
        CGFloat v = [rot velocity];

        XNAnimation *a = [[XNAnimation alloc] initWithKeyPath:@"transform.rotation"];
        
        BOOL vel;
        XNTimingFunction *tf = [self tf:&vel];
        [a setTimingFunction:tf];
        if (!vel) {
            [a setDuration:0.5f];
        } else {
            [a setVelocity:[NSNumber numberWithFloat:v]];
        }

        [a setToValue:[NSNumber numberWithFloat:0]];
        [brick addXNAnimation:a];
    }
}

@end
