//
//  BSON_Helper.h
//  ObjCMongoDB
//
//  Copyright 2012 Paul Melnikow and other contributors
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "BSON_Helper.h"

NSString * NSStringFromBSONString (const char *cString) {
    if (!cString) return nil;
    return [NSString stringWithCString:cString encoding:NSUTF8StringEncoding];
}

const char * BSONStringFromNSString (NSString * key) {
    return [key cStringUsingEncoding:NSUTF8StringEncoding];
}

void BSONAssertKeyNonNil(NSString *key) {
    if (key) return;
    id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"Key must not be nil"
                                 userInfo:nil];
    @throw exc;
}

void BSONAssertKeyLegalForMongoDB(NSString *key) {
    BSONAssertKeyNonNil(key);
    if ([key hasPrefix:@"$"]) {
        NSString *reason = [NSString stringWithFormat:@"Invalid key %@ - MongoDB keys may not begin with '$'",
                            key];
        id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                         reason:reason
                                       userInfo:nil];
        @throw exc;
    } else if (NSNotFound != [key rangeOfString:@"."].location) {
        NSString *reason = [NSString stringWithFormat:@"Invalid key %@ - MongoDB keys may not contain '.'",
                            key];
        id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                         reason:reason
                                       userInfo:nil];
        @throw exc;
    }
}

void BSONAssertValueNonNil(id value) {
    if (value) return;
    id exc = [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"Value must not be nil"
                                 userInfo:nil];
    @throw exc;
}

void BSONAssertIteratorIsValueType(BSONIterator * iterator, bson_type valueType) {
    if (iterator && iterator.nativeValueType == valueType) return;
    NSString *reason = [NSString stringWithFormat:@"Operation requires BSON type %@, but has %@ instead",
                        NSStringFromBSONType(valueType),
                        NSStringFromBSONType(iterator.nativeValueType),
                        nil];
    id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                   reason:reason
                                 userInfo:nil];
    @throw exc;
}

void BSONAssertIteratorIsInValueTypeArray(BSONIterator * iterator, bson_type * valueType) {
    if (iterator) return;
    for (bson_type *cur = valueType; cur < valueType + sizeof(valueType); ++cur)
        if (iterator.nativeValueType == *cur) return;
    NSMutableArray *allowedTypes = [NSMutableArray array];
    for (bson_type *cur = valueType; cur < valueType + sizeof(valueType); ++cur)
        [allowedTypes addObject:NSStringFromBSONType(*cur)];

    NSString *reason = [NSString stringWithFormat:@"Operation requires one of BSON types %@, but has %@ instead",
                        allowedTypes,
                        NSStringFromBSONType(iterator.nativeValueType),
                        nil];
    id exc = [NSException exceptionWithName:NSInvalidUnarchiveOperationException
                                   reason:reason
                                 userInfo:nil];
    @throw exc;
}

NSString * NSStringFromBSONType(bson_type t) {
    NSString *name = nil;
    switch(t) {
        case BSON_EOO:
            name = @"BSON_EOO"; break;
        case BSON_DOUBLE:
            name = @"BSON_DOUBLE"; break;
        case BSON_STRING:
            name = @"BSON_STRING"; break;
        case BSON_OBJECT:
            name = @"BSON_OBJECT"; break;
        case BSON_ARRAY:
            name = @"BSON_ARRAY"; break;
        case BSON_BINDATA:
            name = @"BSON_BINDATA"; break;
        case BSON_UNDEFINED:
            name = @"BSON_UNDEFINED"; break;
        case BSON_OID:
            name = @"BSON_OID"; break;
        case BSON_BOOL:
            name = @"BSON_BOOL"; break;
        case BSON_DATE:
            name = @"BSON_DATE"; break;
        case BSON_NULL:
            name = @"BSON_NULL"; break;
        case BSON_REGEX:
            name = @"BSON_REGEX"; break;
        case BSON_CODE:
            name = @"BSON_CODE"; break;
        case BSON_SYMBOL:
            name = @"BSON_SYMBOL"; break;
        case BSON_CODEWSCOPE:
            name = @"BSON_CODEWSCOPE"; break;
        case BSON_INT:
            name = @"BSON_INT"; break;
        case BSON_TIMESTAMP:
            name = @"BSON_TIMESTAMP"; break;
        case BSON_LONG:
            name = @"BSON_LONG"; break;
        default:
            name = [NSString stringWithFormat:@"(%i) ???", t];
    }
    return name;
}

NSString * NSStringFromBSONError(int err) {
    NSMutableArray *errors = [NSMutableArray array];
    if (err & BSON_NOT_UTF8) [errors addObject:@"BSON_NOT_UTF8"];
    if (err & BSON_FIELD_HAS_DOT) [errors addObject:@"BSON_FIELD_HAS_DOT"];
    if (err & BSON_FIELD_INIT_DOLLAR) [errors addObject:@"BSON_FIELD_INIT_DOLLAR"];
    if (err & BSON_ALREADY_FINISHED) [errors addObject:@"BSON_ALREADY_FINISHED"];
    
    if (errors.count)
        return [errors componentsJoinedByString:@" | "];
    else
        return @"BSON_VALID";
}

NSMutableString * target_for_bson_substitute_for_printf = nil;

int substitute_for_printf(const char *format, ...) {
    if (!target_for_bson_substitute_for_printf) return 0;
    
    va_list args;
    va_start(args, format);
    NSString *stringToAppend = [[NSString alloc] initWithFormat:NSStringFromBSONString(format) arguments:args];
    va_end(args);    
    
    [target_for_bson_substitute_for_printf appendString:stringToAppend];
    
#if !__has_feature(objc_arc)
    [stringToAppend release];
#endif
    return 0;
}

NSString * NSStringFromBSON(const bson * b) {
    target_for_bson_substitute_for_printf = [NSMutableString string];
    bson_errprintf = bson_printf = substitute_for_printf;
    bson_print(b);
    bson_errprintf = bson_printf = printf;
    NSString *result = [target_for_bson_substitute_for_printf stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    target_for_bson_substitute_for_printf = nil;
    return result;
}

NSData * NSDataFromBSON (const bson * b, BOOL copy) {
    if (!b) return nil;
    void *bytes = (void *)bson_data(b);
    int size = bson_size(b);
    if (copy)
        return [NSData dataWithBytes:bytes length:size];
    else
        return [NSData dataWithBytesNoCopy:bytes length:size freeWhenDone:NO];
}