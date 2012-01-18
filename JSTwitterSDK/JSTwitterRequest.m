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
@synthesize requestType = _requestType;
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
        _endpoint = [endpoint retain];
        _requestType = JSTwitterRequestTypeGET;
        // Prevent a duplicate forward slash
        // Doubles cause a bad OAuth signature!
        if ([kJSTwitterRestServerURL hasSuffix:@"/"] && [endpoint hasPrefix:@"/"]) {
            endpoint = [endpoint substringWithRange:NSMakeRange(1, endpoint.length-1)];
        }
        [self setURL:[NSURL URLWithString:[kJSTwitterRestServerURL stringByAppendingFormat:@"%@.json", endpoint]]];
        [self setHTTPMethod:@"GET"];
    }
    return self;
}

- (id)initWithRestEndpoint:(NSString *)endpoint requestType:(JSTwitterRequestType)requestType
{
    self = [super init];
    if (self) {
        _endpoint = [endpoint retain];
        _requestType = requestType;
        [self setURL:[NSURL URLWithString:[kJSTwitterRestServerURL stringByAppendingFormat:@"%@.json", endpoint]]];
        switch (requestType) {
            case JSTwitterRequestTypePOST:
                [self setHTTPMethod:@"POST"];
                break;
            default:
                [self setHTTPMethod:@"GET"];
                break;
        }
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
