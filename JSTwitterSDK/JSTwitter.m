//
//  JSTwitter.m
//  KinoSporedi
//
//  Created by Jernej Strasner on 7/28/10.
//  Copyright 2010 JernejStrasner.com. All rights reserved.
//

#import "JSTwitter.h"

#import "JSONKit.h"
#import "JSTwitter-NSDictionary.h"


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


@interface JSTwitter () {
	// Dispatch
	dispatch_queue_t twitterQueue;
}

@property (nonatomic, retain) OAToken *oauthToken;
@property (nonatomic, retain) OAConsumer *oauthConsumer;

@end

@implementation JSTwitter

#pragma mark - Properties

@synthesize oauthConsumerKey = _oauthConsumerKey;
@synthesize oauthConsumerSecret = _oauthConsumerSecret;

@synthesize oauthToken = _oauthToken;

- (void)setOauthToken:(OAToken *)oauthToken
{
    if (_oauthToken == oauthToken) return;
    [oauthToken retain];
    id oldVal = _oauthToken;
    _oauthToken = oauthToken;
    [oldVal release];
    // Save the token
    [oauthToken storeInUserDefaultsWithServiceProviderName:kJSTwitterAccessTokenDefaultsKey prefix:@""];
}

- (OAToken *)oauthToken
{
#if REMEMBER_ACCESS_TOKEN
    if (_oauthToken == nil) {
        _oauthToken = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:kJSTwitterAccessTokenDefaultsKey prefix:@""];
    }
#endif
    return _oauthToken;
}

@synthesize oauthConsumer = _oauthConsumer;

- (OAConsumer *)oauthConsumer
{
	if (!_oauthConsumer) {
		_oauthConsumer = [[OAConsumer alloc] initWithKey:self.oauthConsumerKey secret:self.oauthConsumerSecret];
	}
	return _oauthConsumer;
}

@synthesize username = _username;

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
		OAConsumer *consumer = [self oauthConsumer];
		// Initialize the request
		OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url consumer:consumer token:nil realm:nil signatureProvider:nil] autorelease];
        [request setOAuthParameterName:@"oauth_callback" withValue:kJSTwitterOauthCallbackURL];
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
        
		if (error == nil) {
			// If request was successful check the HTTP response codes
			// Log errors to the console
			switch (requestStatusCode) {
				case 200:
					NSLog(@"%@: Request sucessfull!", [self class]);
					break;
				case 400:
					NSLog(@"%@: Bad request or rate limited.", [self class]);
					break;
				case 401:
					NSLog(@"%@: Authorization failed.", [self class]);
					break;
				case 500:
					NSLog(@"%@: Internal server error.", [self class]);
					break;
				case 502:
					NSLog(@"%@: Twitter is down or being upgraded.", [self class]);
					break;
				case 503:
					NSLog(@"%@: The Twitter servers are up, but overloaded with requests. Try again later.", [self class]);
					break;
				default:
					NSLog(@"%@: %d: %@", [self class], requestStatusCode, [NSHTTPURLResponse localizedStringForStatusCode:requestStatusCode]);
					break;
			}
			// Call the sucess/error function on the main thread
			if (requestStatusCode != 200) {
				// Call the error function
				dispatch_async(dispatch_get_main_queue(), ^{
                    errorHandler(nil);
				});
			} else {
				// Get the request token data
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
			
		} else {
			// The NSURLConnection could not be made
			NSLog(@"%@: NSURLConnection error: %@", [self class], [error localizedDescription]);
			// Call the error function
			dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(nil);
			});
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
		OAConsumer *consumer = [self oauthConsumer];
		// The request token to exchange
		OAToken *token = [[[OAToken alloc] initWithKey:requestToken secret:requestTokenSecret] autorelease];
		// Initialize the request
		OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url consumer:consumer token:token realm:nil signatureProvider:nil] autorelease];
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
		
		if (error == nil) {
			// If request was successful check the HTTP response codes
			// Log errors to the console
			switch (requestStatusCode) {
				case 200:
					NSLog(@"%@: Request sucessfull!", [self class]);
					break;
				case 400:
					NSLog(@"%@: Bad request or rate limited.", [self class]);
					break;
				case 401:
					NSLog(@"%@: Authorization failed.", [self class]);
					break;
				case 500:
					NSLog(@"%@: Internal server error.", [self class]);
					break;
				case 502:
					NSLog(@"%@: Twitter is down or being upgraded.", [self class]);
					break;
				case 503:
					NSLog(@"%@: The Twitter servers are up, but overloaded with requests. Try again later.", [self class]);
					break;
				default:
					NSLog(@"%@: %d: %@", [self class], requestStatusCode, [NSHTTPURLResponse localizedStringForStatusCode:requestStatusCode]);
					break;
			}
			// Call the sucess/error function on the main thread
			if (requestStatusCode != 200) {
				// Call the error function
				dispatch_async(dispatch_get_main_queue(), ^{
                    errorHandler(nil);
				});
			} else {
				// Get the request token data
				// Parse the returned data
                NSLog(@"Data: %@", jsonData);
				NSArray *parameters = [jsonData componentsSeparatedByString:@"&"];
				NSMutableDictionary *accessTokenData = [NSMutableDictionary new];
				NSArray *temp;
				for (NSString *parameter in parameters) {
					temp = [parameter componentsSeparatedByString:@"="];
					[accessTokenData setObject:[temp objectAtIndex:1] forKey:[temp objectAtIndex:0]];
				}
				
				dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Got access token data: %@", accessTokenData);
					self.oauthToken = [[[OAToken alloc] initWithKey:[accessTokenData valueForKey:@"oauth_token"] secret:[accessTokenData valueForKey:@"oauth_token_secret"]] autorelease];
                    [_username release];
                    _username = [[accessTokenData valueForKey:@"screen_name"] retain];

                    completionHandler();
				});
				
				[accessTokenData release];
			}
			
		} else {
			// The NSURLConnection could not be made
			NSLog(@"%@: NSURLConnection error: %@", [self class], [error localizedDescription]);
			// Call the error function
			dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(nil);
			});
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
        OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:_request.URL
                                                                        consumer:[self oauthConsumer]
                                                                           token:[self oauthToken]
                                                                           realm:nil
                                                               signatureProvider:nil] autorelease];
        [request setHTTPMethod:_request.HTTPMethod];
        NSMutableArray *params = [NSMutableArray array];
        for (NSString *k in _request.twitterParameters) {
            [params addObject:[OARequestParameter requestParameterWithName:k value:[_request.twitterParameters valueForKey:k]]];
        }
        [request setParameters:params];
        
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
        // The response object
        id resolvedResponse = nil;
        // If request was successful check the HTTP response codes
        // Log errors to the console
        switch (requestStatusCode) {
            case 200:
                NSLog(@"%@: Request sucessfull!", [self class]);
                break;
            case 400:
                NSLog(@"%@: Bad request or rate limited.", [self class]);
                break;
            case 401:
                NSLog(@"%@: Authorization failed.", [self class]);
                break;
            case 500:
                NSLog(@"%@: Internal server error.", [self class]);
                break;
            case 502:
                NSLog(@"%@: Twitter is down or being upgraded.", [self class]);
                break;
            case 503:
                NSLog(@"%@: The Twitter servers are up, but overloaded with requests. Try again later.", [self class]);
                break;
            default:
                NSLog(@"%@: %d: %@", [self class], requestStatusCode, [NSHTTPURLResponse localizedStringForStatusCode:requestStatusCode]);
                break;
        }
        // Call the sucess/error function on the main thread
        if (requestStatusCode != 200) {
            // Decode the JSON response
            resolvedResponse = [jsonData objectFromJSONString];
            // Debug
            NSLog(@"%@: Error:\nRequest: %@\nError description: %@", [self class], [resolvedResponse objectForKey:@"request"], [resolvedResponse objectForKey:@"error"]);
            // Prepare the error
            NSError *theError = [NSError errorWithDomain:@"com.jernejstrasner.twitter" code:100 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[resolvedResponse objectForKey:@"error"], NSLocalizedDescriptionKey, nil]];
            // Execute the error block
            dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(theError);
            });
        } else {
            // Resolve the response to an object
            // If there is an error on the server side it will get resolved to an NSMutableDictionary with "error" and "request" keys
            resolvedResponse = [jsonData objectFromJSONString];
            // Execute the completion block
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(resolvedResponse);
            });
        }
        
        [pool drain];
    });
}

@end
