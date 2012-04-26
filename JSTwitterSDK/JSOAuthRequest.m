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
	id val;
    for (NSString *k in [self oauthParameters]) {
		val = [[self oauthParameters] valueForKey:k];
		if ([val isKindOfClass:[NSString class]] == NO) {
			if ([val isKindOfClass:[UIImage class]]) {
				val = [[[NSString alloc] initWithData:UIImageJPEGRepresentation(val, 0.8f) encoding:NSASCIIStringEncoding] autorelease];
			}
			else if ([val isKindOfClass:[NSData class]]) {
				val = [[[NSString alloc] initWithData:val encoding:NSASCIIStringEncoding] autorelease];
			}
			else {
				[NSException raise:@"Parameter processing exception" format:@"Parameters must be instances of NSString, UIImage or NSData!"];
			}
		}
        [joinedParameters addObject:[NSString stringWithFormat:@"%@=\"%@\"", k, [val URLEncodedString]]];
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
    NSString *signature = [[self signatureBaseString] HMACSHA1SignatureWithSecret:signingString];
    [oauthHeader appendFormat:@", oauth_signature=\"%@\"", [signature URLEncodedString]];
    
    // Finally, set the header value
    [self setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
}

- (NSString *)signatureBaseString
{
    NSMutableArray *signatureParameters = [NSMutableArray array];
    
	id val;
    for (NSString *k in [self oauthParameters]) {
		val = [[self oauthParameters] valueForKey:k];
		if ([val isKindOfClass:[NSString class]] == NO) {
			if ([val isKindOfClass:[UIImage class]]) {
				val = [[[NSString alloc] initWithData:UIImageJPEGRepresentation(val, 0.8f) encoding:NSASCIIStringEncoding] autorelease];
			}
			else if ([val isKindOfClass:[NSData class]]) {
				val = [[[NSString alloc] initWithData:val encoding:NSASCIIStringEncoding] autorelease];
			}
			else {
				[NSException raise:@"Parameter processing exception" format:@"Parameters must be instances of NSString, UIImage or NSData!"];
			}
		}
        [signatureParameters addObject:[NSString stringWithFormat:@"%@=%@", k, [val URLEncodedString]]];
    }
    
    // Check other request parameters
    if ([[self HTTPMethod] isEqualToString:@"POST"]) {
        NSString *postString = [[[NSString alloc] initWithData:[self HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
        if ([postString length] > 0) {
            [signatureParameters addObjectsFromArray:[postString componentsSeparatedByString:@"&"]];
        }
    }
    
    NSString *urlString = [[self URL] absoluteString];
    NSUInteger queryStart = [urlString rangeOfString:@"?"].location;
    if (queryStart != NSNotFound) {
        NSString *getString = [urlString substringFromIndex:queryStart+1];
        if ([getString length] > 0) {
            [signatureParameters addObjectsFromArray:[getString componentsSeparatedByString:@"&"]];
        }
    }
        
    [signatureParameters sortUsingSelector:@selector(compare:)];
    
    NSString *ret = [NSString stringWithFormat:@"%@&%@&%@",
					 [self HTTPMethod],
					 [[[self URL] URLStringWithoutQuery] URLEncodedString],
					 [[signatureParameters componentsJoinedByString:@"&"] URLEncodedString]];

	return ret;
}

@end
