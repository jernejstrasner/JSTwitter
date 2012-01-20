//
//  JSTwitter.m
//  KinoSporedi
//
//  Created by Jernej Strasner on 7/28/10.
//  Copyright 2010 JernejStrasner.com. All rights reserved.
//

#import "JSTwitter.h"

#import "JSONKit.h"
#import "NSDictionary+HTTP.h"
#import "JSOAuthRequest.h"


#define REMEMBER_ACCESS_TOKEN 1

#ifdef DEBUG
#   define REQUEST_TIMEOUT 60
#else
#   define REQUEST_TIMEOUT 20
#endif

// Constants
NSString * const kJSTwitterRestServerURL            = @"https://api.twitter.com/1/";
NSString * const kJSTwitterOauthServerURL           = @"https://api.twitter.com/oauth/";
NSString * const kJSTwitterSearchServerURL          = @"http://search.twitter.com/";
NSString * const kJSTwitterOauthCallbackURL         = @"jstwitter://successful/";
NSString * const kJSTwitterStringBoundary           = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";
NSString * const kJSTwitterAccessTokenDefaultsKey   = @"com.jstwitter.token";
NSString * const kJSTwitterNetworkErrorDomain       = @"com.jstwitter.error.network";
NSString * const kJSTwitterOtherErrorDomain         = @"com.jstwitter.error.other";


@interface JSTwitter () {
	// Dispatch
	dispatch_queue_t twitterQueue;
}

@property (nonatomic, retain) JSOAuthToken *oauthToken;
@property (nonatomic, retain) JSOAuthConsumer *oauthConsumer;

- (void)saveUser:(NSString *)user withID:(NSString *)uid;
- (NSError *)twitterErrorForStatusCode:(NSInteger)code;

@end

@implementation JSTwitter

#pragma mark - Properties

@synthesize oauthConsumerKey = _oauthConsumerKey;
@synthesize oauthConsumerSecret = _oauthConsumerSecret;

@synthesize oauthToken = _oauthToken;

- (void)setOauthToken:(JSOAuthToken *)oauthToken
{
    if (_oauthToken == oauthToken) return;
    [oauthToken retain];
    id oldVal = _oauthToken;
    _oauthToken = oauthToken;
    [oldVal release];
    // Save the token
//    [oauthToken storeInUserDefaultsWithServiceProviderName:kJSTwitterAccessTokenDefaultsKey prefix:@""];
}

- (JSOAuthToken *)oauthToken
{
#if REMEMBER_ACCESS_TOKEN
    if (_oauthToken == nil) {
//        _oauthToken = [[JSOAuthToken alloc] initWithUserDefaultsUsingServiceProviderName:kJSTwitterAccessTokenDefaultsKey prefix:@""];
    }
#endif
    return _oauthToken;
}

@synthesize oauthConsumer = _oauthConsumer;

- (JSOAuthConsumer *)oauthConsumer
{
	if (!_oauthConsumer) {
		_oauthConsumer = [[JSOAuthConsumer alloc] initWithKey:self.oauthConsumerKey secret:self.oauthConsumerSecret];
	}
	return _oauthConsumer;
}

@synthesize username = _username;
@synthesize userID = _userID;

- (void)saveUser:(NSString *)user withID:(NSString *)uid
{
    [_username release];
    [_userID release];
    _username = [user retain];
    _userID = [uid retain];
    // Save to defaults
    [[NSUserDefaults standardUserDefaults] setValue:user forKey:@"com.jstwitter.user.name"];
    [[NSUserDefaults standardUserDefaults] setValue:uid forKey:@"com.jstwitter.user.id"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Singleton

+ (JSTwitter *)sharedInstance
{
    static JSTwitter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[JSTwitter alloc] init];
    });
	return sharedInstance;
}

#pragma mark - Object lifecycle

- (id)init
{
    self = [super init];
	if (self) {
		// Set up the dispatch queue
		twitterQueue = dispatch_queue_create("com.jstwitter.network", NULL);
        // Get the user info if saved
        _username = [[[NSUserDefaults standardUserDefaults] valueForKey:@"com.jstwitter.user.name"] retain];
        _userID = [[[NSUserDefaults standardUserDefaults] valueForKey:@"com.jstwitter.user.id"] retain];
	}
	return self;
}

- (void)dealloc
{
	dispatch_release(twitterQueue);
	
    [_oauthConsumerKey release];
    [_oauthConsumerSecret release];
	[_oauthToken release];
	[_oauthConsumer release];
    
    [_username release];
    [_userID release];
	
	[super dealloc];
}

#pragma mark - Authentication

- (void)authenticateWithCompletionHandler:(jstwitter_auth_success_block_t)completionHandler
                             errorHandler:(jstwitter_auth_error_block_t)errorHandler
{
    if (self.oauthToken) {
        completionHandler();
    } else {
        JSTwitterAuthController *authController = [JSTwitterAuthController authControllerWithConsumerKey:self.oauthConsumerKey consumerSecret:self.oauthConsumerSecret];
        authController.completionHandler = completionHandler;
        authController.errorHandler = errorHandler;
        UIViewController *viewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        [viewController presentModalViewController:authController animated:YES];
    }
}

#pragma mark - OAuth methods

- (void)getRequestTokenWithCompletionHandler:(jstwitter_request_token_success_block_t)completionHandler
                                errorHandler:(jstwitter_error_block_t)errorHandler
{	
	dispatch_async(twitterQueue, ^{
		// Make the URL
		NSString *theURLString = [kJSTwitterOauthServerURL stringByAppendingString:@"request_token"];	
		// Cast the url in the NSURL object
		NSURL *url = [NSURL URLWithString:theURLString];
		
		// The consumer object
		JSOAuthConsumer *consumer = [self oauthConsumer];
		// Initialize the request
		JSOAuthRequest *request = [[[JSOAuthRequest alloc] initWithURL:url consumer:consumer token:nil] autorelease];
        [request setOAuthParameterValue:kJSTwitterOauthCallbackURL forKey:@"oauth_callback"];
		// Set the HTTP method
		[request setHTTPMethod:@"POST"];
		// Set the request time out interval in seconds
		[request setTimeoutInterval:REQUEST_TIMEOUT];
		// Custom OAuthConsumer method to prepare the request
		[request prepare];
		
		// Make the request
		NSHTTPURLResponse *response = nil;
		NSError *error = nil;
		NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		NSString *jsonData = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];

		// Check the response
		NSInteger requestStatusCode = [response statusCode];
        
        if (requestStatusCode != 200) {
            // Get the error object
            NSError *error = [self twitterErrorForStatusCode:requestStatusCode];
            // Call the error function
            dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(error);
            });
        } else {
            // Parse the returned data
            NSArray *parameters = [jsonData componentsSeparatedByString:@"&"];
            NSMutableDictionary *requestTokenData = [NSMutableDictionary new];
            NSArray *temp;
            for (NSString *parameter in parameters) {
                temp = [parameter componentsSeparatedByString:@"="];
                [requestTokenData setObject:[temp objectAtIndex:1] forKey:[temp objectAtIndex:0]];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // Request the display of a dialog
                completionHandler([requestTokenData valueForKey:@"oauth_token"], [requestTokenData valueForKey:@"oauth_token_secret"]);
            });
            
            [requestTokenData release];
        }
	});
}

- (void)getAcessTokenForRequestToken:(NSString *)requestToken
                  requestTokenSecret:(NSString *)requestTokenSecret
                   completionHandler:(jstwitter_success_block_t)completionHandler
                        errorHandler:(jstwitter_error_block_t)errorHandler
{
	dispatch_async(twitterQueue, ^{
		// Make the URL
		NSString *theURLString = [kJSTwitterOauthServerURL stringByAppendingString:@"access_token"];	
		// Cast the url in the NSURL object
		NSURL *url = [NSURL URLWithString:theURLString];
		
		// The consumer object
		JSOAuthConsumer *consumer = [self oauthConsumer];
		// The request token to exchange
		JSOAuthToken *token = [[[JSOAuthToken alloc] initWithKey:requestToken secret:requestTokenSecret] autorelease];
		// Initialize the request
		JSOAuthRequest *request = [[[JSOAuthRequest alloc] initWithURL:url consumer:consumer token:token] autorelease];
		// Set the HTTP method
		[request setHTTPMethod:@"POST"];
		// Set the request time out interval in seconds
		[request setTimeoutInterval:REQUEST_TIMEOUT];
		// Custom OAuthConsumer method to prepare the request
		[request prepare];
		
		// Make the request
		NSHTTPURLResponse *response = nil;
		NSError *error = nil;
		NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		NSString *jsonData = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
		
		// Check the response
		NSInteger requestStatusCode = [response statusCode];
		
        if (requestStatusCode != 200) {
            // Get the error object
            NSError *error = [self twitterErrorForStatusCode:requestStatusCode];
            // Call the error function
            dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(error);
            });
        } else {
            // Parse the returned data
            NSArray *parameters = [jsonData componentsSeparatedByString:@"&"];
            NSMutableDictionary *accessTokenData = [NSMutableDictionary new];
            NSArray *temp;
            for (NSString *parameter in parameters) {
                temp = [parameter componentsSeparatedByString:@"="];
                [accessTokenData setObject:[temp objectAtIndex:1] forKey:[temp objectAtIndex:0]];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.oauthToken = [[[JSOAuthToken alloc] initWithKey:[accessTokenData valueForKey:@"oauth_token"] secret:[accessTokenData valueForKey:@"oauth_token_secret"]] autorelease];
                [self saveUser:[accessTokenData valueForKey:@"screen_name"] withID:[accessTokenData valueForKey:@"user_id"]];

                completionHandler();
            });
            
            [accessTokenData release];
        }
	});
}

#pragma mark - Requests

- (void)fetchRequest:(JSTwitterRequest *)_request
           onSuccess:(jstwitter_success_data_block_t)completionHandler
             onError:(jstwitter_error_block_t)errorHandler
{
    // Check if authorized
	if (!self.oauthToken) {
		NSLog(@"Not authorized!");
        errorHandler(nil);
        return;
	}
    
    // Dispatch
    dispatch_async(twitterQueue, ^{
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // Initialize the request
        JSOAuthRequest *request = [[[JSOAuthRequest alloc] initWithURL:_request.URL consumer:[self oauthConsumer] token:[self oauthToken]] autorelease];
        [request setHTTPMethod:_request.HTTPMethod];
//        NSMutableArray *params = [NSMutableArray array];
//        for (NSString *k in _request.twitterParameters) {
//            [params addObject:[OARequestParameter requestParameterWithName:k value:[_request.twitterParameters valueForKey:k]]];
//        }
//        [request setParameters:params];
        
        // Set the request time out interval in seconds
        [request setTimeoutInterval:REQUEST_TIMEOUT];
        
        // Custom OAuthConsumer method to prepare the request
        [request prepare];
        
        NSHTTPURLResponse *response = nil;
        NSError *error = nil;
        // We should probably be parsing the data returned by this call, for now just check the error.
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        NSString *jsonData = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
        
        NSInteger requestStatusCode = [response statusCode];
        id resolvedResponse = nil;

        if (requestStatusCode != 200) {
            // Error
            error = [self twitterErrorForStatusCode:requestStatusCode];
            // Decode the JSON response (if any)
            resolvedResponse = [jsonData objectFromJSONString];
            // Execute the error block
            dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(error);
            });
        } else {
            // Resolve the response to an object.
            // If there is an error on the server side it will get resolved
            // to an NSMutableDictionary with "error" and "request" keys.
            resolvedResponse = [jsonData objectFromJSONString];
            // Execute the completion block
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(resolvedResponse);
            });
        }
        
        [pool drain];
    });
}

#pragma mark - Utility methods

- (NSError *)twitterErrorForStatusCode:(NSInteger)code
{
    NSString *errorDescription;
    switch (code) {
        case 200:
            return nil;
            break;
        case 400:
            errorDescription = @"Bad request or rate limited";
            break;
        case 401:
            errorDescription = @"Authorization failed";
            break;
        case 500:
            errorDescription = @"Internal server error";
            break;
        case 502:
            errorDescription = @"Twitter is down or being upgraded";
            break;
        case 503:
            errorDescription = @"The Twitter servers are up, but overloaded with requests";
            break;
        default:
            errorDescription = [NSHTTPURLResponse localizedStringForStatusCode:code];
            break;
    }
    return [NSError errorWithDomain:kJSTwitterNetworkErrorDomain code:code userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:NSLocalizedDescriptionKey]];
}

@end
