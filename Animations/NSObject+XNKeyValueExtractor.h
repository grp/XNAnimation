//
//  NSObject+XNKeyValueExtractor.h
//  Animations
//
//  Created by Grant Paul on 12/2/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

// To avoid conflicts, "XNKeyPath" is used instead of "KeyPath".
// Note: Compared to the built-in KVC, this allows structure introspection.
@interface NSObject (XNKeyValueExtractor)

- (id)valueForXNKeyPath:(NSString *)keyPath;
- (void)setValue:(id)value forXNKeyPath:(NSString *)keyPath;

@end
