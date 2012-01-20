//
//  JSOAuthToken.m
//  JSTwitter
//
//  Created by Jernej Strasner on 1/19/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import "JSOAuthToken.h"

#import "JSTwitter.h"

@implementation JSOAuthToken

#pragma mark - Properties

@synthesize key = _key;
@synthesize secret = _secret;

#pragma mark - Lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        self.key = @"";
        self.secret = @"";
    }
    return self;
}

- (id)initWithKey:(NSString *)key secret:(NSString *)secret
{
    self = [super init];
    if (self) {
        _key = [key retain];
        _secret = [secret retain];
    }
    return self;
}

- (id)initFromStorageWithKey:(NSString *)key
{
    self = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    if (self == nil) {
        JSTWLog(@"Could not find token with key %@", key);
    }
    return self;
}

- (void)dealloc
{
    [_key release];
    [_secret release];
    [super dealloc];
}

#pragma mark - Persistence

- (void)storeWithKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] setValue:self forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder allowsKeyedCoding] == NO) {
        [NSException raise:@"JSEncodingException" format:@"Suports only keyed encoders!"];
    }
    [aCoder encodeObject:self.key forKey:@"key"];
    [aCoder encodeObject:self.secret forKey:@"secret"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        if ([aDecoder allowsKeyedCoding] == NO) {
            [NSException raise:@"JSDecodingException" format:@"Suports only keyed decoders!"];
        }
        self.key = [aDecoder decodeObjectForKey:@"key"];
        self.secret = [aDecoder decodeObjectForKey:@"secret"];
    }
    return self;
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: key=%@, secret=%@>", [self class], self.key, self.secret];
}

@end
