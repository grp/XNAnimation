//
//  XNTimingFunction.m
//  Animations
//
//  Created by Grant Paul on 11/24/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNKeyValueExtractor.h"

#import "XNTimingFunction.h"

@implementation XNTimingFunction

#pragma mark - Public

+ (id)timingFunction {
    return [[[self alloc] init] autorelease];
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] alloc] init];
    return copy;
}

#pragma mark - Subclassing

- (CGFloat)durationIndex:(NSUInteger)i from:(CGFloat)from to:(CGFloat)to             velocity:(CGFloat)velocity additional:(id)additional {
    return (to - from) / velocity;
}

- (CGFloat)velocityIndex:(NSUInteger)i from:(CGFloat)from to:(CGFloat)to             duration:(CGFloat)duration additional:(id)additional {
    return (to - from) / duration;
}

- (CGFloat)toIndex:(NSUInteger)i       from:(CGFloat)from duration:(CGFloat)duration velocity:(CGFloat)velocity additional:(id)additional {
    return from + (velocity * duration);
}

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed from:(CGFloat)from to:(CGFloat)to             duration:(CGFloat)duration additional:(id)additional complete:(BOOL *)outComplete {
    if (elapsed >= duration) {
        *outComplete = YES;
        return to;
    } else {
        *outComplete = NO;
        return from;
    }
}

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed from:(CGFloat)from to:(CGFloat)to             velocity:(CGFloat)velocity additional:(id)additional complete:(BOOL *)outComplete {
    *outComplete = YES;
    return to;
}

- (CGFloat)simulateIndex:(NSUInteger)i elapsed:(NSTimeInterval)elapsed from:(CGFloat)from duration:(CGFloat)duration velocity:(CGFloat)velocity additional:(id)additional complete:(BOOL *)outComplete {
    *outComplete = YES;
    return from;
}

#pragma mark - Internal

- (id)valueByEnumeratingValues:(NSArray *)values usingBlock:(id (^)(NSUInteger index, NSArray *values))block {
    XNKeyValueExtractor *keyValueExtractor = [[XNKeyValueExtractor alloc] init];
    NSMutableArray *componentValues = [[NSMutableArray alloc] init];
    NSMutableArray *resultValues = [[NSMutableArray alloc] init];

    for (id value in values) {
        NSArray *componentValue = [keyValueExtractor componentsForObject:value];
        [componentValues addObject:componentValue];
    }

    for (NSUInteger i = 0; i < [[componentValues lastObject] count]; i++) {
        NSMutableArray *extractedValues = [[NSMutableArray alloc] init];

        for (id componentValue in componentValues) {
            id value = [componentValue objectAtIndex:i];
            [extractedValues addObject:value];
        }

        id resultValue = block(i, extractedValues);
        [resultValues addObject:resultValue];

        [extractedValues release];
    }

    id resultValue = [keyValueExtractor objectFromComponents:values templateObject:[values objectAtIndex:0]];

    [componentValues release];
    [keyValueExtractor release];

    return resultValue;
}


- (id)velocityValueFromValue:(id)fromValue toValue:(id)toValue   duration:(id)duration additional:(XNTimingFunctionAdditional *)additional {
    return [self valueByEnumeratingValues:[NSArray arrayWithObjects:fromValue, toValue, duration, nil] usingBlock:^id (NSUInteger index, NSArray *values) {
        NSNumber *fromValue = [values objectAtIndex:0];
        NSNumber *toValue = [values objectAtIndex:1];
        NSNumber *durationValue = [values objectAtIndex:2];
        id additionalValue = [values objectAtIndex:3];

        CGFloat from = [fromValue floatValue];
        CGFloat to = [toValue floatValue];
        CGFloat duration = [durationValue floatValue];

        CGFloat velocity = [self velocityIndex:index from:from to:to duration:duration additional:additionalValue];
        NSNumber *velocityValue = [NSNumber numberWithFloat:velocity];

        return velocityValue;
    }];
}

- (id)durationValueFromValue:(id)fromValue toValue:(id)toValue   velocity:(id)velocity additional:(XNTimingFunctionAdditional *)additional {
    return [self valueByEnumeratingValues:[NSArray arrayWithObjects:fromValue, toValue, velocity, nil] usingBlock:^id (NSUInteger index, NSArray *values) {
        NSNumber *fromValue = [values objectAtIndex:0];
        NSNumber *toValue = [values objectAtIndex:1];
        NSNumber *velocityValue = [values objectAtIndex:2];
        id additionalValue = [values objectAtIndex:3];

        CGFloat from = [fromValue floatValue];
        CGFloat to = [toValue floatValue];
        CGFloat velocity = [velocityValue floatValue];

        CGFloat duration = [self durationIndex:index from:from to:to velocity:velocity additional:additionalValue];
        NSNumber *durationValue = [NSNumber numberWithFloat:duration];

        return durationValue;
    }];
}

- (id)toValueFromValue:(id)fromValue       duration:(id)duration velocity:(id)velocity additional:(XNTimingFunctionAdditional *)additional {
    return [self valueByEnumeratingValues:[NSArray arrayWithObjects:fromValue, duration, velocity, nil] usingBlock:^id (NSUInteger index, NSArray *values) {
        NSNumber *fromValue = [values objectAtIndex:0];
        NSNumber *durationValue = [values objectAtIndex:1];
        NSNumber *velocityValue = [values objectAtIndex:2];
        id additionalValue = [values objectAtIndex:3];

        CGFloat from = [fromValue floatValue];
        CGFloat duration = [durationValue doubleValue];
        CGFloat velocity = [velocityValue floatValue];

        CGFloat to = [self toIndex:index from:from duration:duration velocity:velocity additional:additionalValue];
        NSNumber *toValue = [NSNumber numberWithFloat:to];

        return toValue;
    }];
}

#pragma mark - Simulate

- (id)simulateWithElapsed:(NSTimeInterval)elapsed fromValue:(id)fromValue toValue:(id)toValue   duration:(id)duration additional:(XNTimingFunctionAdditional *)additional complete:(BOOL *)outComplete {
    return [self valueByEnumeratingValues:[NSArray arrayWithObjects:fromValue, toValue, duration, additional, nil] usingBlock:^id (NSUInteger index, NSArray *values) {
        NSNumber *fromValue = [values objectAtIndex:0];
        NSNumber *durationValue = [values objectAtIndex:1];
        NSNumber *velocityValue = [values objectAtIndex:2];
        id additionalValue = [values objectAtIndex:3];

        CGFloat from = [fromValue floatValue];
        CGFloat duration = [durationValue doubleValue];
        CGFloat velocity = [velocityValue floatValue];

        BOOL complete = NO;

        CGFloat position = [self simulateIndex:index elapsed:elapsed from:from duration:duration velocity:velocity additional:additionalValue complete:&complete];
        NSNumber *positionValue = [NSNumber numberWithFloat:position];

        if (outComplete != NULL) {
            *outComplete = (*outComplete && complete);
        }

        return positionValue;
    }];
}

- (id)simulateWithElapsed:(NSTimeInterval)elapsed fromValue:(id)fromValue toValue:(id)toValue   velocity:(id)velocity additional:(XNTimingFunctionAdditional *)additional complete:(BOOL *)outComplete {
    return [self valueByEnumeratingValues:[NSArray arrayWithObjects:fromValue, toValue, velocity, additional, nil] usingBlock:^id (NSUInteger index, NSArray *values) {
        NSNumber *fromValue = [values objectAtIndex:0];
        NSNumber *toValue = [values objectAtIndex:1];
        NSNumber *velocityValue = [values objectAtIndex:2];
        id additionalValue = [values objectAtIndex:3];

        CGFloat from = [fromValue floatValue];
        CGFloat to = [toValue doubleValue];
        CGFloat velocity = [velocityValue floatValue];

        BOOL complete = NO;

        CGFloat position = [self simulateIndex:index elapsed:elapsed from:from to:to velocity:velocity additional:additionalValue complete:&complete];
        NSNumber *positionValue = [NSNumber numberWithFloat:position];

        if (outComplete != NULL) {
            *outComplete = (*outComplete && complete);
        }

        return positionValue;
    }];
}

- (id)simulateWithElapsed:(NSTimeInterval)elapsed fromValue:(id)fromValue duration:(id)duration velocity:(id)velocity additional:(XNTimingFunctionAdditional *)additional complete:(BOOL *)outComplete {
    return [self valueByEnumeratingValues:[NSArray arrayWithObjects:fromValue, duration, velocity, additional, nil] usingBlock:^id (NSUInteger index, NSArray *values) {
        NSNumber *fromValue = [values objectAtIndex:0];
        NSNumber *durationValue = [values objectAtIndex:1];
        NSNumber *velocityValue = [values objectAtIndex:2];
        id additionalValue = [values objectAtIndex:3];

        CGFloat from = [fromValue floatValue];
        CGFloat duration = [durationValue doubleValue];
        CGFloat velocity = [velocityValue floatValue];

        BOOL complete = NO;

        CGFloat position = [self simulateIndex:index elapsed:elapsed from:from duration:duration velocity:velocity additional:additionalValue complete:&complete];
        NSNumber *positionValue = [NSNumber numberWithFloat:position];

        if (outComplete != NULL) {
            *outComplete = (*outComplete && complete);
        }

        return positionValue;
    }];
}

@end
