//
//  JSOAuthRequest.m
//  JSTwitter
//
//  Created by Jernej Strasner on 1/19/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import "JSOAuthRequest.h"

#import "NSString+URLEncoding.h"
#import "NSURL+Base.h"
#import "NSString+JSOAuthSigning.h"

#import "OAHMAC_SHA1SignatureProvider.h"

@interface JSOAuthRequest ()

@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, retain) NSString *nonce;

- (void)initialize;
- (NSString *)signatureBaseString;

@end

@implementation JSOAuthRequest

#pragma mark - Properties

@synthesize consumer = _consumer;

- (void)setConsumer:(JSOAuthConsumer *)consumer
{
    if (_consumer == consumer) return;
    [consumer retain];
    id oldVal = _consumer;
    _consumer = consumer;
    [oldVal release];
    
    [self setOAuthParameterValue:consumer.key forKey:@"oauth_consumer_key"];
}

@synthesize token = _token;

- (void)setToken:(JSOAuthToken *)token
{
    if (_token == token) return;
    [token retain];
    id oldVal = _token;
    _token = token;
    [oldVal release];
    
    [self setOAuthParameterValue:token.key forKey:@"oauth_token"];
}

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
    
    // Set default parameters
    [self setOAuthParameterValue:@"1.0" forKey:@"oauth_version"];
    [self setOAuthParameterValue:@"HMAC-SHA1" forKey:@"oauth_signature_method"];
    [self setOAuthParameterValue:[NSString stringWithFormat:@"%0.0f", _timestamp] forKey:@"oauth_timestamp"];
    [self setOAuthParameterValue:_nonce forKey:@"oauth_nonce"];
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

- (void)prepare
{    
    // Begin building the header string
    NSMutableString *oauthHeader = [NSMutableString string];
    [oauthHeader appendString:@"OAuth "];

    // Add all oauth parameters
    NSMutableArray *joinedParameters = [NSMutableArray array];
    for (NSString *k in [self oauthParameters]) {
        [joinedParameters addObject:[NSString stringWithFormat:@"%@=\"%@\"", k, [[[self oauthParameters] valueForKey:k] URLEncodedString]]];
    }
    [joinedParameters sortUsingSelector:@selector(compare:)];
    [oauthHeader appendString:[joinedParameters componentsJoinedByString:@", "]];
    
    // Add the signature
    NSMutableString *signingString = [NSMutableString string];
    [signingString appendString:[self.consumer.secret URLEncodedString]];
    [signingString appendString:@"&"];
    if (self.token != nil) {
        [signingString appendString:[self.token.secret URLEncodedString]];
    }
//    NSString *signature = [[self signatureBaseString] HMACSHA1SignatureWithSecret:signingString];
    NSString *signature = [[[[OAHMAC_SHA1SignatureProvider alloc] init] autorelease] signClearText:[self signatureBaseString] withSecret:signingString];
    [oauthHeader appendFormat:@", oauth_signature=\"%@\"", [signature URLEncodedString]];
    
    // Finally, set the header value
    [self setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
}

- (NSString *)signatureBaseString
{
    NSMutableArray *signatureParameters = [NSMutableArray array];
    
    for (NSString *k in [self oauthParameters]) {
        [signatureParameters addObject:[NSString stringWithFormat:@"%@=%@", k, [[[self oauthParameters] valueForKey:k] URLEncodedString]]];
    }
        
    [signatureParameters sortUsingSelector:@selector(compare:)];
    
    NSString *ret = [NSString stringWithFormat:@"%@&%@&%@",
					 [self HTTPMethod],
					 [[[self URL] URLStringWithoutQuery] URLEncodedString],
					 [[signatureParameters componentsJoinedByString:@"&"] URLEncodedString]];

	return ret;
}

@end
