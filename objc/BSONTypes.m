//
//  BSONTypes.m
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

#import "BSONTypes.h"

@implementation BSONObjectID

#pragma mark - Initialization

- (id) init {
    if (self = [super init]) {
        bson_oid_gen(&_oid);
    }
    return self;
}

- (id) initWithString:(NSString *) s {
    if (s.length != 24) {
        [self release];
        [NSException raise:NSInvalidArgumentException format:@"String should be 24 characters long"];
    }
    if (self = [super init]) {
        bson_oid_from_string(&_oid, BSONStringFromNSString(s));
    }
    return self;
}

- (id) initWithData:(NSData *) data {
    if ((self = [super init])) {
        if ([data length] != 12) {
#if !__has_feature(objc_arc)
            [self release];
#endif
            return nil;
        }
        memcpy(_oid.bytes, [data bytes], 12);
    }
    return self;
}

- (id) initWithNativeOID:(const bson_oid_t *) objectIDPointer {
    if (self = [super init]) {
        _oid = *objectIDPointer;
    }
    return self;
}

- (void) dealloc {
#if !__has_feature(objc_arc)
    [_stringValue release];
    [super dealloc];
#endif
}

+ (BSONObjectID *) objectID {
#if __has_feature(objc_arc)
    return [[self alloc] init];
#else
    return [[[self alloc] init] autorelease];
#endif
}

+ (BSONObjectID *) objectIDWithString:(NSString *) s {
    if (s.length != 24) return nil;
#if __has_feature(objc_arc)
    return [[self alloc] initWithString:s];
#else
    return [[[self alloc] initWithString:s] autorelease];
#endif
}

+ (BSONObjectID *) objectIDWithData:(NSData *) data {
#if __has_feature(objc_arc)
    return [[self alloc] initWithData:data];
#else
    return [[[self alloc] initWithData:data] autorelease];
#endif
}

+ (BSONObjectID *) objectIDWithNativeOID:(const bson_oid_t *) objectIDPointer {
#if __has_feature(objc_arc)
    return [[self alloc] initWithNativeOID:objectIDPointer];
#else
    return [[[self alloc] initWithNativeOID:objectIDPointer] autorelease];
#endif
}

- (id) copyWithZone:(NSZone *) zone {
	return [[BSONObjectID allocWithZone:zone] initWithNativeOID:&_oid];
}

- (const bson_oid_t *) objectIDPointer { return &_oid; }

- (bson_oid_t) oid { return _oid; }


- (NSData *) dataValue {
    return [NSData dataWithBytes:_oid.bytes length:12];
}

- (NSDate *) dateGenerated {
    return [NSDate dateWithTimeIntervalSince1970:bson_oid_generated_time(&_oid)];
}

- (NSUInteger) hash {
	return _oid.ints[0] + _oid.ints[1] + _oid.ints[2];
}

- (NSString *) description {
    return [NSString stringWithFormat:@"Object ID \"%@\"", [self stringValue]];
}

- (NSString *) stringValue {
    if (_stringValue) return _stringValue;
    // str must be at least 24 hex chars + null byte
    char buffer[25];
    bson_oid_to_string(&_oid, buffer);
#if __has_feature(objc_arc)
    return _stringValue = NSStringFromBSONString(buffer);
#else
    return _stringValue = [NSStringFromBSONString(buffer) retain];
#endif
}

- (NSComparisonResult)compare:(BSONObjectID *) other {
    if (!other) [NSException raise:NSInvalidArgumentException format:@"Nil argument"];
    for (int i = 0; i < 3; i++) {
        int diff = _oid.ints[i] - other->_oid.ints[i];
        if (diff < 0)
            return NSOrderedAscending;
        else if (diff > 0)
            return NSOrderedDescending;
    }
    return NSOrderedSame;
}

- (BOOL)isEqual:(id)other {
    if (![other isKindOfClass:[BSONObjectID class]]) return NO;
    return [self compare:other] == NSOrderedSame;
}

@end

@implementation BSONRegularExpression
@synthesize pattern, options;

+ (BSONRegularExpression *) regularExpressionWithPattern:(NSString *) pattern options:(NSString *) options {
    BSONRegularExpression *obj = [[self alloc] init];
    obj.pattern = pattern;
    obj.options = options;
#if __has_feature(objc_arc)
    return obj;
#else
    return [obj autorelease];
#endif
}

@end

@implementation  BSONTimestamp

- (BSONTimestamp *) initWithNativeTimestamp:(bson_timestamp_t) timestamp {
    if (self = [super init]) {
        _timestamp = timestamp;
    }
    return self;
}

+ (BSONTimestamp *) timestampWithNativeTimestamp:(bson_timestamp_t) timestamp {
#if __has_feature(objc_arc)
    return [[self alloc] initWithNativeTimestamp:timestamp];
#else
    return [[[self alloc] initWithNativeTimestamp:timestamp] autorelease];
#endif
}

+ (BSONTimestamp *) timestampWithIncrement:(int) increment timeInSeconds:(int) time {
    BSONTimestamp *obj = [[self alloc] init];
    obj.increment = increment;
    obj.timeInSeconds = time;
#if __has_feature(objc_arc)
    return obj;
#else
    return [obj autorelease];
#endif
}

- (bson_timestamp_t *) timestampPointer {
    return &_timestamp;
}

- (int) increment { return _timestamp.i; }
- (void) setIncrement:(int) increment {
    [self willChangeValueForKey:@"increment"];
    _timestamp.i = increment;
    [self didChangeValueForKey:@"increment"];
}
- (int) timeInSeconds { return _timestamp.t; }
- (void) setTimeInSeconds:(int) timeInSeconds {
    [self willChangeValueForKey:@"timeInSeconds"];
    _timestamp.t = timeInSeconds;
    [self didChangeValueForKey:@"timeInSeconds"];
}

@end

@implementation BSONCode
@synthesize code;

+ (BSONCode *) code:(NSString *) code {
    BSONCode *obj = [[self alloc] init];
    obj.code = code;
#if __has_feature(objc_arc)
    return obj;
#else
    return [obj autorelease];
#endif
}

@end

@implementation BSONCodeWithScope
@synthesize scope;

+ (BSONCodeWithScope *) code:(NSString *) code withScope:(BSONDocument *) scope {
    BSONCodeWithScope *obj = [[self alloc] init];
    obj.code = code;
    obj.scope = scope;
#if __has_feature(objc_arc)
    return obj;
#else
    return [obj autorelease];
#endif
}

@end

@implementation BSONSymbol
@synthesize symbol;

+ (BSONSymbol *) symbol:(NSString *)symbol {
    BSONSymbol *obj = [[self alloc] init];
    obj.symbol = symbol;
#if __has_feature(objc_arc)
    return obj;
#else
    return [obj autorelease];
#endif
}

@end