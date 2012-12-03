//
//  XNKeyValueExtractor.h
//  Animations
//
//  Created by Grant Paul on 11/26/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XNKeyValueExtractor : NSObject

- (id)object:(id)object valueForKeyPath:(NSString *)keyPath;
- (void)object:(id)object setValue:(id)value forKeyPath:(NSString *)keyPath;
- (NSArray *)componentsForObject:(id)object;
- (id)objectFromComponents:(NSArray *)components templateObject:(id)object;

@end
