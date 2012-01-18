//
//  JSTwitterRequest.m
//  JSTwitter
//
//  Created by Jernej Strasner on 1/17/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import "JSTwitterRequest.h"
#import "JSTwitter.h"

@interface JSTwitterRequest () {
    NSMutableDictionary *_parameters;
}

@end

@implementation JSTwitterRequest

#pragma mark - Properties

@synthesize endpoint = _endpoint;
@synthesize requestType = _requestType;

- (NSDictionary *)parameters
{
    return [NSDictionary dictionaryWithDictionary:_parameters];
}

- (void)addParameter:(id)value withKey:(NSString *)key
{
    if (_parameters == nil) {
        _parameters = [[NSMutableDictionary alloc] init];
    }
    [_parameters setValue:value forKey:key];
}

- (void)removeParameterWithKey:(NSString *)key
{
    [_parameters removeObjectForKey:key];
}

#pragma mark - Object lifecycle

- (id)initWithRestEndpoint:(NSString *)endpoint
{
    self = [super init];
    if (self) {
        _endpoint = [endpoint retain];
        _requestType = JSTwitterRequestTypeGET;
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
    [_parameters release];
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
