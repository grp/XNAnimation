//
//  NSObject+XNKeyValueExtractor.m
//  Animations
//
//  Created by Grant Paul on 12/2/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import "XNKeyValueExtractor.h"

#import "NSObject+XNKeyValueExtractor.m"

@implementation NSObject (XNKeyValueExtractor)

static XNKeyValueExtractor *keyValueExtractor = nil;

__attribute__((constructor)) static void NSObjectXNKeyValueExtractorInitialize() {
    keyValueExtractor = [[XNKeyValueExtractor alloc] init];
}

- (id)valueForXNKeyPath:(NSString *)keyPath {
    return [keyValueExtractor object:self valueForKeyPath:keyPath];
}

- (void)setValue:(id)value forXNKeyPath:(NSString *)keyPath {
    [keyValueExtractor object:self setValue:value forKeyPath:keyPath];
}

@end
