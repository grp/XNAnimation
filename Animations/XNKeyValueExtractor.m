//
//  XNKeyValueExtractor.m
//  Animations
//
//  Created by Grant Paul on 11/26/12.
//  Copyright (c) 2012 Xuzz Productions, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "XNKeyValueExtractor.h"

@implementation XNKeyValueExtractor {
    CALayer *_hackLayer;
}

- (id)init {
    if ((self = [super init])) {
        _hackLayer = [[CALayer alloc] init];
    }

    return self;
}

- (void)dealloc {
    [_hackLayer release];

    [super dealloc];
}

- (id)object:(id)object valueForKeyPath:(NSString *)keyPath {
    NSArray *components = [keyPath componentsSeparatedByString:@"."];
    id value = object;

    for (NSUInteger i = 0; i < [components count]; i++) {
        NSString *key = [components objectAtIndex:i];
        NSString *nextKey = ([components count] > i + 1) ? [components objectAtIndex:(i + 1)] : nil;

        if ([key hasPrefix:@"@"]) {
            [NSException raise:@"XNKeyValueExtractorInvalidKeyPathException" format:@"collection operators are not supported"];
        }

        @try {
            // Separate out these lines so any exceptions thrown jump to the
            // catch below before setting the value object. (Is this needed?)
            id keyValue = [value valueForKey:key];
            value = keyValue;
        } @catch (NSException *e) {
            if ([value isKindOfClass:[NSValue class]]) {
                NSString *type = [NSString stringWithUTF8String:[value objCType]];

                if ([type isEqualToString:@"{CGPoint=ff}"] || [type isEqualToString:@"{NSPoint=ff}"]) {
                    CGPoint point = [value CGPointValue];

                    if ([key isEqualToString:@"x"]) {
                        value = [NSNumber numberWithFloat:point.x];
                    } else if ([key isEqualToString:@"y"]) {
                        value = [NSNumber numberWithFloat:point.y];
                    } else {
                        [e raise];
                    }
                } else if ([type isEqualToString:@"{CGSize=ff}"] || [type isEqualToString:@"{NSSize=ff}"]) {
                    CGSize size = [value CGSizeValue];

                    if ([key isEqualToString:@"width"]) {
                        value = [NSNumber numberWithFloat:size.width];
                    } else if ([key isEqualToString:@"height"]) {
                        value = [NSNumber numberWithFloat:size.height];
                    } else {
                        [e raise];
                    }
                } else if ([type isEqualToString:@"{CGRect={CGPoint=ff}{CGSize=ff}}"] || [type isEqualToString:@"{NSRect={NSPoint=ff}{NSSize=ff}}"]) {
                    CGRect rect = [value CGRectValue];

                    if ([key isEqualToString:@"origin"]) {
                        value = [NSValue valueWithCGPoint:rect.origin];
                    } else if ([key isEqualToString:@"size"]) {
                        value = [NSValue valueWithCGSize:rect.size];
                    } else {
                        [e raise];
                    }
                } else if ([type isEqualToString:@"{CGAffineTransform=ffffff}"]) {
                    CGAffineTransform transform = [value CGAffineTransformValue];
                    [_hackLayer setAffineTransform:transform];

                    if ([key isEqualToString:@"rotation"]) {
                        value = [_hackLayer valueForKeyPath:@"transform.rotation"];
                    } else if ([key isEqualToString:@"scale"]) {
                        if (nextKey != nil) {
                            if ([nextKey isEqualToString:@"x"]) {
                                i += 1;
                                value = [_hackLayer valueForKeyPath:@"transform.scale.x"];
                            } else if ([nextKey isEqualToString:@"y"]) {
                                i += 1;
                                value = [_hackLayer valueForKeyPath:@"transform.scale.y"];
                            } else {
                                [e raise];
                            }
                        } else {
                            value = [_hackLayer valueForKeyPath:@"transform.scale"];
                        }
                    } else if ([key isEqualToString:@"translation"]) {
                        if (nextKey != nil) {
                            if ([nextKey isEqualToString:@"x"]) {
                                i += 1;
                                value = [_hackLayer valueForKeyPath:@"transform.translation.x"];
                            } else if ([nextKey isEqualToString:@"y"]) {
                                i += 1;
                                value = [_hackLayer valueForKeyPath:@"transform.translation.y"];
                            } else {
                                [e raise];
                            }
                        } else {
                            value = [_hackLayer valueForKeyPath:@"transform.translation"];
                        }
                    } else {
                        [e raise];
                    }
                } else if ([type isEqualToString:@"{CATransform3D=ffffffffffffffff}"]) {
                    CATransform3D transform = [value CATransform3DValue];
                    [_hackLayer setTransform:transform];

                    if ([key isEqualToString:@"rotation"]) {
                        if (nextKey != nil) {
                            if ([nextKey isEqualToString:@"x"]) {
                                i += 1;
                                value = [_hackLayer valueForKeyPath:@"transform.rotation.x"];
                            } else if ([nextKey isEqualToString:@"y"]) {
                                i += 1;
                                value = [_hackLayer valueForKeyPath:@"transform.rotation.y"];
                            } else if ([nextKey isEqualToString:@"z"]) {
                                i += 1;
                                value = [_hackLayer valueForKeyPath:@"transform.rotation.z"];
                            } else {
                                [e raise];
                            }
                        } else {
                            value = [_hackLayer valueForKeyPath:@"transform.rotation"];
                        }
                    } else if ([key isEqualToString:@"scale"]) {
                        if (nextKey != nil) {
                            if ([nextKey isEqualToString:@"x"]) {
                                i += 1;
                                value = [_hackLayer valueForKeyPath:@"transform.scale.x"];
                            } else if ([nextKey isEqualToString:@"y"]) {
                                i += 1;
                                value = [_hackLayer valueForKeyPath:@"transform.scale.y"];
                            } else if ([nextKey isEqualToString:@"z"]) {
                                i += 1;
                                value = [_hackLayer valueForKeyPath:@"transform.scale.z"];
                            } else {
                                [e raise];
                            }
                        } else {
                            value = [_hackLayer valueForKeyPath:@"transform.scale"];
                        }
                    } else if ([key isEqualToString:@"translation"]) {
                        if (nextKey != nil) {
                            if ([nextKey isEqualToString:@"x"]) {
                                i += 1;
                                value = [_hackLayer valueForKeyPath:@"transform.translation.x"];
                            } else if ([nextKey isEqualToString:@"y"]) {
                                i += 1;
                                value = [_hackLayer valueForKeyPath:@"transform.translation.y"];
                            } else if ([nextKey isEqualToString:@"z"]) {
                                i += 1;
                                value = [_hackLayer valueForKeyPath:@"transform.translation.z"];
                            } else {
                                [e raise];
                            }
                        } else {
                            value = [_hackLayer valueForKeyPath:@"transform.translation"];
                        }
                    } else {
                        [e raise];
                    }
                } else {
                    [e raise];
                }
            } else {
                [e raise];
            }
        }
    }

    return value;
}

- (void)object:(id)object setValue:(id)v forKeyPath:(NSString *)keyPath {
    if ([[keyPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        [NSException raise:@"XNKeyValueExtractorInvalidKeyPathException" format:@"key paths must not be empty"];
    }

    NSArray *components = [keyPath componentsSeparatedByString:@"."];
    NSArray *remainingComponents = [NSArray arrayWithObject:[components lastObject]];

    NSException *exception = nil;
    
    id value = object;
    id previousValue = value;

    for (NSUInteger i = 0; i < [components count]; i++) {
        NSString *key = [components objectAtIndex:i];
        
        if ([key hasPrefix:@"@"]) {
            [NSException raise:@"XNKeyValueExtractorInvalidKeyPathException" format:@"collection operators are not supported"];
        }

        @try {
            // Separate out these lines so any exceptions thrown jump to the
            // catch below before setting the value object. (Is this needed?)
            id keyValue = [value valueForKey:key];
            previousValue = value;
            value = keyValue;
        } @catch (NSException *e) {
            exception = e; // save to rethrow if this really is an error
            remainingComponents = [components subarrayWithRange:NSMakeRange(i - 1, [components count] - i + 1)];
            break;
        }
    }

    if (exception == nil) {
        exception = [NSException exceptionWithName:@"XNKeyValueExtractorUnknownException" reason:@"dunno" userInfo:nil];
    }

    value = previousValue;

    NSString *initialRemainingKey = [remainingComponents objectAtIndex:0];

    if ([remainingComponents count] == 1) {
        [value setValue:v forKey:initialRemainingKey];
    } else {
        NSException *e = exception;
        id current = [value valueForKey:initialRemainingKey];

        if ([current isKindOfClass:[NSValue class]]) {
            NSString *type = [NSString stringWithUTF8String:[current objCType]];

            NSString *key = ([remainingComponents count] > 1) ? [remainingComponents objectAtIndex:1] : nil;
            NSString *nextKey = ([remainingComponents count] > 2) ? [remainingComponents objectAtIndex:2] : nil;

            if ([type isEqualToString:@"{CGPoint=ff}"] || [type isEqualToString:@"{NSPoint=ff}"]) {
                CGPoint point = [current CGPointValue];

                if ([key isEqualToString:@"x"]) {
                    point.x = [v floatValue];
                } else if ([key isEqualToString:@"y"]) {
                    point.y = [v floatValue];
                } else {
                    [e raise];
                }

                [value setValue:[NSValue valueWithCGPoint:point] forKey:initialRemainingKey];
            } else if ([type isEqualToString:@"{CGSize=ff}"] || [type isEqualToString:@"{NSSize=ff}"]) {
                CGSize size = [current CGSizeValue];

                if ([key isEqualToString:@"width"]) {
                    size.width = [v floatValue];
                } else if ([key isEqualToString:@"height"]) {
                    size.height = [v floatValue];
                } else {
                    [e raise];
                }

                [value setValue:[NSValue valueWithCGSize:size] forKey:initialRemainingKey];
            } else if ([type isEqualToString:@"{CGRect={CGPoint=ff}{CGSize=ff}}"] || [type isEqualToString:@"{NSRect={NSPoint=ff}{NSSize=ff}}"]) {
                CGRect rect = [current CGRectValue];

                if ([key isEqualToString:@"origin"]) {
                    if ([nextKey isEqualToString:@"x"]) {
                        rect.origin.x = [v floatValue];
                    } else if ([nextKey isEqualToString:@"y"]) {
                        rect.origin.y = [v floatValue];
                    } else {
                        rect.origin= [v CGPointValue];
                    }
                } else if ([key isEqualToString:@"size"]) {
                    if ([nextKey isEqualToString:@"width"]) {
                        rect.size.width = [v floatValue];
                    } else if ([nextKey isEqualToString:@"height"]) {
                        rect.size.height = [v floatValue];
                    } else {
                        rect.size = [v CGSizeValue];
                    }
                } else {
                    [e raise];
                }

                [value setValue:[NSValue valueWithCGRect:rect] forKey:initialRemainingKey];
            } else if ([type isEqualToString:@"{CGAffineTransform=ffffff}"]) {
                CGAffineTransform transform = [current CGAffineTransformValue];
                [_hackLayer setAffineTransform:transform];

                if ([key isEqualToString:@"rotation"]) {
                    [_hackLayer setValue:v forKeyPath:@"transform.rotation"];
                } else if ([key isEqualToString:@"scale"]) {
                    if (nextKey != nil) {
                        if ([nextKey isEqualToString:@"x"]) {
                            [_hackLayer setValue:v forKeyPath:@"transform.scale.x"];
                        } else if ([nextKey isEqualToString:@"y"]) {
                            [_hackLayer setValue:v forKeyPath:@"transform.scale.y"];
                        } else {
                            [e raise];
                        }
                    } else {
                        [_hackLayer setValue:v forKeyPath:@"transform.scale"];
                    }
                } else if ([key isEqualToString:@"translation"]) {
                    if (nextKey != nil) {
                        if ([nextKey isEqualToString:@"x"]) {
                            [_hackLayer setValue:v forKeyPath:@"transform.translation.x"];
                        } else if ([nextKey isEqualToString:@"y"]) {
                            [_hackLayer setValue:v forKeyPath:@"transform.translation.y"];
                        } else {
                            [e raise];
                        }
                    } else {
                        [_hackLayer setValue:v forKeyPath:@"transform.translation"];
                    }
                } else {
                    [e raise];
                }

                transform = CATransform3DGetAffineTransform([_hackLayer transform]);
                [value setValue:[NSValue valueWithCGAffineTransform:transform] forKey:initialRemainingKey];
            } else if ([type isEqualToString:@"{CATransform3D=ffffffffffffffff}"]) {
                CATransform3D transform = [current CATransform3DValue];
                [_hackLayer setTransform:transform];

                if ([key isEqualToString:@"rotation"]) {
                    if (nextKey != nil) {
                        if ([nextKey isEqualToString:@"x"]) {
                            [_hackLayer setValue:v forKeyPath:@"transform.rotation.x"];
                        } else if ([nextKey isEqualToString:@"y"]) {
                            [_hackLayer setValue:v forKeyPath:@"transform.rotation.y"];
                        } else if ([nextKey isEqualToString:@"z"]) {
                            [_hackLayer setValue:v forKeyPath:@"transform.rotation.z"];
                        } else {
                            [e raise];
                        }
                    } else {
                        [_hackLayer setValue:v forKeyPath:@"transform.rotation"];
                    }
                } else if ([key isEqualToString:@"scale"]) {
                    if (nextKey != nil) {
                        if ([nextKey isEqualToString:@"x"]) {
                            [_hackLayer setValue:v forKeyPath:@"transform.scale.x"];
                        } else if ([nextKey isEqualToString:@"y"]) {
                            [_hackLayer setValue:v forKeyPath:@"transform.scale.y"];
                        } else if ([nextKey isEqualToString:@"z"]) {
                            [_hackLayer setValue:v forKeyPath:@"transform.scale.z"];
                        } else {
                            [e raise];
                        }
                    } else {
                        [_hackLayer setValue:v forKeyPath:@"transform.scale"];
                    }
                } else if ([key isEqualToString:@"translation"]) {
                    if (nextKey != nil) {
                        if ([nextKey isEqualToString:@"x"]) {
                            [_hackLayer setValue:v forKeyPath:@"transform.translation.x"];
                        } else if ([nextKey isEqualToString:@"y"]) {
                            [_hackLayer setValue:v forKeyPath:@"transform.translation.y"];
                        } else if ([nextKey isEqualToString:@"z"]) {
                            [_hackLayer setValue:v forKeyPath:@"transform.translation.z"];
                        } else {
                            [e raise];
                        }
                    } else {
                        [_hackLayer setValue:v forKeyPath:@"transform.translation"];
                    }
                } else {
                    [e raise];
                }

                transform = [_hackLayer transform];
                [value setValue:[NSValue valueWithCATransform3D:transform] forKey:initialRemainingKey];
            } else {
                [e raise];
            }
        } else {
            [e raise];
        }
    }
}

- (NSString *)flattenedTypeEncodingForTypeEncoding:(const char *)types totalSize:(NSUInteger *)outTotalSize {
    NSMutableString *flattened = [NSMutableString string];

    char *methodTypes = malloc(strlen(types) + 4);
    methodTypes[0] = '@'; // return type
    methodTypes[1] = '@'; // self
    methodTypes[2] = ':'; // _cmd
    strcpy(methodTypes + 3, types); // arguments

    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:methodTypes];
    NSUInteger itemCount = [methodSignature numberOfArguments];

    free(methodTypes);

    NSUInteger totalSize = 0;

    for (NSUInteger i = 2; i < itemCount; i++) {
        const char *type = [methodSignature getArgumentTypeAtIndex:i];
        NSUInteger currentSize = 0;

        if (type[0] == '(') {
            [NSException raise:@"XNKeyValueExtractorUnsupportedTypeException" format:@"union types not supported"];
        } else if (type[0] == '[') {
            [NSException raise:@"XNKeyValueExtractorUnsupportedTypeException" format:@"arrays types not (yet?) supported"];
        } else if (type[0] == '^') {
            [NSException raise:@"XNKeyValueExtractorUnsupportedTypeException" format:@"pointer types not supported"];
        } else if (type[0] == 'b') {
            [NSException raise:@"XNKeyValueExtractorUnsupportedTypeException" format:@"bitfield types not supported"];
        } else if (type[0] == '*') {
            [NSException raise:@"XNKeyValueExtractorUnsupportedTypeException" format:@"character pointer types not supported"];
        } else if (type[0] == '#') {
            [NSException raise:@"XNKeyValueExtractorUnsupportedTypeException" format:@"class types not supported"];
        } else if (type[0] == '@') {
            [NSException raise:@"XNKeyValueExtractorUnsupportedTypeException" format:@"object types not supported"];
        } else if (type[0] == ':') {
            [NSException raise:@"XNKeyValueExtractorUnsupportedTypeException" format:@"selector types not supported"];
        } else if (type[0] == '?') {
            [NSException raise:@"XNKeyValueExtractorUnsupportedTypeException" format:@"unknown types not supported"];
        } else if (type[0] == 'v') {
            [NSException raise:@"XNKeyValueExtractorUnsupportedTypeException" format:@"void types not supported"];
        } else if (type[0] == '{') {
            NSUInteger start = 1;
            NSUInteger end = strlen(type) - 1;
            for (NSUInteger j = start; j <= end; j++) {
                if (type[j] == '=') {
                    start = j + 1;
                    break;
                } else if (!isalnum(type[j])) {
                    break;
                }
            }

            char *contents = malloc(end - start + 1);
            strncpy(contents, type + start, end - start);
            contents[end - start] = 0;

            NSString *contentsString = [self flattenedTypeEncodingForTypeEncoding:contents totalSize:&currentSize];
            [flattened appendString:contentsString];

            free(contents);
        } else {
            NSGetSizeAndAlignment(type, NULL, &currentSize);

            [flattened appendFormat:@"%s", type];
        }

        totalSize += currentSize;
    }

    if (outTotalSize != NULL) {
        *outTotalSize = totalSize;
    }

    return flattened;
}

- (NSArray *)componentsForValue:(NSValue *)value {
    NSMutableArray *components = [NSMutableArray array];

    const char *typeEncoding = [value objCType];
    NSUInteger totalSize = 0;
    NSString *flattened = [self flattenedTypeEncodingForTypeEncoding:typeEncoding totalSize:&totalSize];
    const char *flattenedTypes = [flattened UTF8String];

    void *bytes = malloc(totalSize);
    [value getValue:bytes];
    NSUInteger offset = 0;

    for (NSUInteger i = 0; i < strlen(flattenedTypes); i++) {
        char type = flattenedTypes[i];

        char typestr[2] = { type, 0 };
        NSUInteger size = 0;
        NSGetSizeAndAlignment(typestr, NULL, &size);

        NSNumber *number = nil;

        if (type == @encode(float)[0]) {
            float f;
            memcpy(&f, (bytes + offset), size);
            number = [NSNumber numberWithFloat:f];
        } else if (type == @encode(double)[0]) {
            double d;
            memcpy(&d, (bytes + offset), size);
            number = [NSNumber numberWithDouble:d];
        } else {
            long long value = 0;
            memcpy(&value, (bytes + offset), size);
            number = [NSNumber numberWithLongLong:value];
        }

        offset += size;
        [components addObject:number];
    }

    free(bytes);

    return components;
}

- (NSValue *)valueFromComponents:(NSArray *)components templateValue:(NSValue *)value {
    const char *types = [value objCType];

    NSUInteger totalSize = 0;
    NSString *flattened = [self flattenedTypeEncodingForTypeEncoding:types totalSize:&totalSize];
    const char *flattenedTypes = [flattened UTF8String];

    if (strlen(flattenedTypes) == 1) {
        return [components objectAtIndex:0];
    } else {
        void *bytes = calloc(1, totalSize);
        NSUInteger offset = 0;

        for (NSUInteger i = 0; i < strlen(flattenedTypes); i++) {
            char type = flattenedTypes[i];
            NSNumber *part = [components objectAtIndex:i];

            char typestr[2] = { type, 0 };
            NSUInteger size = 0;
            NSGetSizeAndAlignment(typestr, NULL, &size);

            if (type == @encode(float)[0]) {
                float f = [part floatValue];
                memcpy(bytes + offset, &f, sizeof(f));
            } else if (type == @encode(double)[0]) {
                double d = [part doubleValue];
                memcpy(bytes + offset, &d, sizeof(d));
            } else if (type == @encode(char)[0]) {
                char c = [part charValue];
                memcpy(bytes + offset, &c, sizeof(c));
            } else if (type == @encode(int)[0]) {
                int i = [part intValue];
                memcpy(bytes + offset, &i, sizeof(i));
            } else if (type == @encode(short)[0]) {
                short s = [part shortValue];
                memcpy(bytes + offset, &s, sizeof(s));
            } else if (type == @encode(long)[0]) {
                long l = [part longValue];
                memcpy(bytes + offset, &l, sizeof(l));
            } else if (type == @encode(long long)[0]) {
                long long ll = [part longLongValue];
                memcpy(bytes + offset, &ll, sizeof(ll));
            } else if (type == @encode(unsigned char)[0]) {
                unsigned char uc = [part unsignedCharValue];
                memcpy(bytes + offset, &uc, sizeof(uc));
            } else if (type == @encode(unsigned int)[0]) {
                unsigned int ui = [part unsignedIntValue];
                memcpy(bytes + offset, &ui, sizeof(ui));
            } else if (type == @encode(unsigned short)[0]) {
                unsigned short us = [part unsignedShortValue];
                memcpy(bytes + offset, &us, sizeof(us));
            } else if (type == @encode(unsigned long)[0]) {
                unsigned long long ul = [part unsignedLongValue];
                memcpy(bytes + offset, &ul, sizeof(ul));
            } else if (type == @encode(unsigned long long)[0]) {
                unsigned long long ull = [part unsignedLongLongValue];
                memcpy(bytes + offset, &ull, sizeof(ull));
            } else if (type == @encode(_Bool)[0]) {
                _Bool b = [part boolValue];
                memcpy(bytes + offset, &b, sizeof(b));
            }
            
            offset += size;
        }
        
        NSValue *value = [NSValue valueWithBytes:bytes objCType:types];
        free(bytes);
        return value;
    }
}

- (NSArray *)componentsForColor:(CGColorRef)color {
    CGColorSpaceRef colorSpace = CGColorGetColorSpace(color);
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(colorSpace);
    
    if (colorSpaceModel != kCGColorSpaceModelMonochrome && colorSpaceModel != kCGColorSpaceModelRGB) {
        [NSException raise:@"XNKeyValueExtractorInvalidColorSpaceException" format:@"only colors in RGB and monochrome color spaces are supported"];
    }

    const CGFloat *componentValues = CGColorGetComponents(color);

    NSNumber *red = nil;
    NSNumber *green = nil;
    NSNumber *blue = nil;
    NSNumber *alpha = nil;

    if (colorSpaceModel == kCGColorSpaceModelRGB) {
        red = [NSNumber numberWithFloat:componentValues[0]];
        green = [NSNumber numberWithFloat:componentValues[1]];
        blue = [NSNumber numberWithFloat:componentValues[2]];
        alpha = [NSNumber numberWithFloat:componentValues[3]];
    } else if (colorSpaceModel == kCGColorSpaceModelMonochrome) {
        red = [NSNumber numberWithFloat:componentValues[0]];
        green = [NSNumber numberWithFloat:componentValues[0]];
        blue = [NSNumber numberWithFloat:componentValues[0]];
        alpha = [NSNumber numberWithFloat:componentValues[1]];
    }

    return [NSArray arrayWithObjects:red, green, blue, alpha, nil];
}

- (CGColorRef)colorFromComponents:(NSArray *)components templateColor:(CGColorRef)color {
    CGColorSpaceRef colorSpace = CGColorGetColorSpace(color);
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(colorSpace);

    if (colorSpaceModel != kCGColorSpaceModelMonochrome && colorSpaceModel != kCGColorSpaceModelRGB) {
        [NSException raise:@"XNKeyValueExtractorInvalidColorSpaceException" format:@"only colors in RGB and monochrome color spaces are supported"];
    }

    NSNumber *red = [components objectAtIndex:0];
    NSNumber *green = [components objectAtIndex:1];
    NSNumber *blue = [components objectAtIndex:2];
    NSNumber *alpha = [components objectAtIndex:3];

    CGColorRef result = NULL;

    // Only use a monochrome color space if:
    //  - The template already used a monochrome color space.
    //  - Our color fully fits in a monochrome color space.
    if (red == green && green == blue && blue == red && colorSpaceModel == kCGColorSpaceModelMonochrome) {
        CGFloat components[2] = { [red floatValue], [alpha floatValue] };
        result = CGColorCreate(colorSpace, components);
    } else {
        CGFloat components[4] = { [red floatValue], [green floatValue], [blue floatValue], [alpha floatValue] };
        result = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
    }

    return result;
}

- (NSArray *)componentsForObject:(id)object {
    if (CFGetTypeID(object) == CGColorGetTypeID()) {
        return [self componentsForColor:(CGColorRef) object];
    } else if ([object isKindOfClass:[UIColor class]]) {
        return [self componentsForColor:[object CGColor]];
    } else if ([object isKindOfClass:[NSNumber class]]) {
        return [NSArray arrayWithObject:object];
    } else if ([object isKindOfClass:[NSValue class]]) {
        return [self componentsForValue:object];
    } else if ([object isKindOfClass:[NSArray class]]) {
        return object;
    } else {
        return nil;
    }
}

- (id)objectFromComponents:(NSArray *)components templateObject:(id)object {
    if (CFGetTypeID(object) == CGColorGetTypeID()) {
        return (id) [self colorFromComponents:components templateColor:(CGColorRef) object];
    } else if ([object isKindOfClass:[UIColor class]]) {
        CGColorRef graphicsColor = [self colorFromComponents:components templateColor:[object CGColor]];
        UIColor *color = [UIColor colorWithCGColor:graphicsColor];
        CFRelease(graphicsColor);
        return color;
    } else if ([object isKindOfClass:[NSNumber class]]) {
        return [components lastObject];
    } else if ([object isKindOfClass:[NSValue class]]) {
        return [self valueFromComponents:components templateValue:object];
    } else if ([object isKindOfClass:[NSArray class]]) {
        return components;
    } else {
        return nil;
    }
}

@end
