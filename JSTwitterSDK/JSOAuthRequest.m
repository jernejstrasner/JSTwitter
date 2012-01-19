//
//  JSOAuthRequest.m
//  JSTwitter
//
//  Created by Jernej Strasner on 1/19/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import "JSOAuthRequest.h"

@interface JSOAuthRequest ()

@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, retain) NSString *nonce;

- (void)initialize;

@end

@implementation JSOAuthRequest

#pragma mark - Properties

@synthesize consumer = _consumer;
@synthesize token = _token;
@synthesize oauthParameters = _oauthParameters;

@synthesize timestamp = _timestamp;
@synthesize nonce = _nonce;

#pragma mark - Lifecycle

- (void)initialize
{
    // Get the UNIX timestamp
    _timestamp = [[NSDate date] timeIntervalSince1970];
    
    // Generate the nonce (unique random string)
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
    _nonce = (NSString *)uuidString;
    CFRelease(uuid);
}

- (id)initWithURL:(NSURL *)URL consumer:(JSOAuthConsumer *)consumer token:(JSOAuthToken *)token
{
    self = [super initWithURL:URL];
    if (self) {
        self.consumer = consumer;
        self.token = token;
        [self initialize];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithURL:(NSURL *)URL
{
    self = [super initWithURL:URL];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval
{
    self = [super initWithURL:URL cachePolicy:cachePolicy timeoutInterval:timeoutInterval];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)dealloc
{
    [_consumer release];
    [_token release];
    [_oauthParameters release];
    
    [_nonce release];
    
    [super dealloc];
}

#pragma mark - Request setup

- (void)setOAuthParameterValue:(id)value forKey:(NSString *)key
{
    if (_oauthParameters == nil) {
        _oauthParameters = [[NSMutableDictionary alloc] init];
    }
    [self.oauthParameters setValue:value forKey:key];
}

@end
