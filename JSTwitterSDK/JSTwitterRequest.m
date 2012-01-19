//
//  JSTwitterRequest.m
//  JSTwitter
//
//  Created by Jernej Strasner on 1/17/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import "JSTwitterRequest.h"
#import "JSTwitter.h"

@implementation JSTwitterRequest

#pragma mark - Properties

@synthesize endpoint = _endpoint;

- (void)setEndpoint:(NSString *)endpoint
{
    if (_endpoint == endpoint) return;
    // Prevent a duplicate forward slash
    // Doubles cause a bad OAuth signature!
    if ([kJSTwitterRestServerURL hasSuffix:@"/"] && [endpoint hasPrefix:@"/"]) {
        endpoint = [endpoint substringWithRange:NSMakeRange(1, endpoint.length-1)];
    }
    [endpoint retain];
    id oldVal = _endpoint;
    _endpoint = endpoint;
    [oldVal release];
    // Set the request URL
    [self setURL:[NSURL URLWithString:[kJSTwitterRestServerURL stringByAppendingFormat:@"%@.json", endpoint]]];
}

@synthesize requestType = _requestType;

- (void)setRequestType:(JSTwitterRequestType)requestType
{
    if (_requestType == requestType) return;
    _requestType = requestType;
    switch (requestType) {
        case JSTwitterRequestTypePOST:
            [self setHTTPMethod:@"POST"];
            break;
        default:
            [self setHTTPMethod:@"GET"];
            break;
    }
}

@synthesize twitterParameters = _twitterParameters;

- (void)addParameter:(id)value withKey:(NSString *)key
{
    if (_twitterParameters == nil) {
        _twitterParameters = [[NSMutableDictionary alloc] init];
    }
    [_twitterParameters setValue:value forKey:key];
}

- (void)removeParameterWithKey:(NSString *)key
{
    [_twitterParameters removeObjectForKey:key];
}

#pragma mark - Object lifecycle

- (id)initWithRestEndpoint:(NSString *)endpoint
{
    self = [super init];
    if (self) {
        self.endpoint = endpoint;
        self.requestType = JSTwitterRequestTypeGET;
    }
    return self;
}

- (id)initWithRestEndpoint:(NSString *)endpoint requestType:(JSTwitterRequestType)requestType
{
    self = [super init];
    if (self) {
        self.endpoint = endpoint;
        self.requestType = requestType;
    }
    return self;
}

- (void)dealloc
{
    [_twitterParameters release];
    [_endpoint release];
    [super dealloc];
}

#pragma mark - Initialization helpers

+ (JSTwitterRequest *)requestWithRestEndpoint:(NSString *)endpoint
{
    return [[[JSTwitterRequest alloc] initWithRestEndpoint:endpoint] autorelease];
}

+ (JSTwitterRequest *)requestWithRestEndpoint:(NSString *)endpoint requestType:(JSTwitterRequestType)requestType
{
    return [[[JSTwitterRequest alloc] initWithRestEndpoint:endpoint requestType:requestType] autorelease];
}

@end
