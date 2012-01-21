//
//  JSTwitterRequest.m
//  JSTwitter
//
//  Created by Jernej Strasner on 1/17/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import "JSTwitterRequest.h"
#import "JSTwitter.h"
#import "NSDictionary+HTTP.h"

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
    [self setURL:[NSURL URLWithString:[kJSTwitterRestServerURL stringByAppendingString:endpoint]]];
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

#pragma mark - Request preparation

- (void)prepare
{    
    if (self.requestType == JSTwitterRequestTypePOST) {
        // POST
        NSString *currentURL = [[self URL] absoluteString];
        
        BOOL hasExt = ([currentURL rangeOfString:@".json"].location != NSNotFound);
        NSUInteger queryStart = [currentURL rangeOfString:@"?"].location;
        BOOL hasParams = (queryStart != NSNotFound);
        
        if (!hasExt) {
            if (hasParams) {
                currentURL = [[currentURL substringToIndex:queryStart] stringByAppendingFormat:@".json%@", [currentURL substringFromIndex:queryStart]];
            } else {
                currentURL = [currentURL stringByAppendingString:@".json"];
            }
            [self setURL:[NSURL URLWithString:currentURL]];
        }        

        NSData *postData = [self.twitterParameters generatePOSTBodyWithBoundary:nil];
        [self setHTTPBody:postData];
        [self setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
        [self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    } else {
        // GET
        NSMutableString *currentURL = [NSMutableString stringWithString:[[self URL] absoluteString]];
        NSString *queryString = [self.twitterParameters generateGETParameters];
        
        BOOL hasExt = ([currentURL rangeOfString:@".json"].location != NSNotFound);
        NSUInteger queryStart = [currentURL rangeOfString:@"?"].location;
        BOOL hasParams = (queryStart != NSNotFound);
        
        if (!hasExt) {
            if (hasParams) {
                [currentURL insertString:@".json" atIndex:queryStart];
            } else {
                [currentURL appendString:@".json"];
            }
        }
        
        if (queryString.length > 0) {
            [currentURL appendString:(hasParams ? @"&" : @"?")];
            [currentURL appendString:queryString];
        }
        
        [self setURL:[NSURL URLWithString:currentURL]];
    }
    
    // We call this after we're done with setting request parameters as otherwise the signature will be incorrect
    [super prepare];
}

@end
