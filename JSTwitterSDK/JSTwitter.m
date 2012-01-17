//
//  JSTwitter.m
//  KinoSporedi
//
//  Created by Jernej Strasner on 7/28/10.
//  Copyright 2010 JernejStrasner.com. All rights reserved.
//

#import "JSTwitter.h"

#import "JSONKit.h"

// Constants
NSString * const kJSTwitterRestServerURL    = @"http://api.twitter.com/1/";
NSString * const kJSTwitterSearchServerURL  = @"http://search.twitter.com/";


@interface JSTwitter () {
	// Dispatch
	dispatch_queue_t twitterQueue;
}

@property (nonatomic, retain) OAToken *oauthToken;
@property (nonatomic, retain) OAConsumer *oauthConsumer;

@end

@implementation JSTwitter

#pragma mark - Properties

@synthesize oauthToken = _oauthToken;
@synthesize oauthConsumer = _oauthConsumer;

#pragma mark - Object lifecycle

- (id)init
{
	if (self = [super init]) {
		// Set up the dispatch queue
		twitterQueue = dispatch_queue_create("com.jernejstrasner.jstwitter", NULL);
	}
	return self;
}

- (BOOL)resumeSessionForUser:(NSString *)user
{
	self.oauthToken = [[[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:@"jernejstrasner.com" prefix:user] autorelease];
	if (!self.oauthToken) {
		return NO;
	}
	return YES;
}

- (BOOL)saveSessionForUser:(NSString *)user
{
	if (!self.oauthToken) {
		return NO;
	}
	[self.oauthToken storeInUserDefaultsWithServiceProviderName:@"jernejstrasner.com" prefix:user];
	return YES;
}

- (void)dealloc
{
	dispatch_release(twitterQueue);
	
	[_oauthToken release];
	[_oauthConsumer release];
	
	[super dealloc];
}

#pragma mark - OAuth methods

- (OAConsumer *)oauthConsumer {
	if (!_oauthConsumer) {
		_oauthConsumer = [[OAConsumer alloc] initWithKey:OAUTH_CONSUMER_KEY secret:OAUTH_CONSUMER_SECRET];
	}
	return _oauthConsumer;
}

- (void)getRequestToken {
	
	dispatch_async(twitterQueue, ^{
		// Make the URL
		NSString *theURLString = @"https://api.twitter.com/oauth/request_token";	
		// Cast the url in the NSURL object
		NSURL *url = [NSURL URLWithString:theURLString];
		
		// The consumer object
		OAConsumer *consumer = [self oauthConsumer];
		// Initialize the request
		OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url consumer:consumer token:nil realm:nil signatureProvider:nil] autorelease];
		// Set the HTTP method
		[request setHTTPMethod:@"POST"];
		// Set the request time out interval in seconds
		[request setTimeoutInterval:20];
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
//					if ([delegate respondsToSelector:@selector(twitterAuthFailed:)]) {
//						[delegate twitterAuthFailed:self];
//					}
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
//					[delegate twitter:self authGotRequestToken:[requestTokenData valueForKey:@"oauth_token"] secret:[requestTokenData valueForKey:@"oauth_token_secret"]];
				});
				
				[requestTokenData release];
			}
			
		} else {
			// The NSURLConnection could not be made
			NSLog(@"%@: NSURLConnection error: %@", [self class], [error localizedDescription]);
			// Call the error function
			dispatch_async(dispatch_get_main_queue(), ^{
//				if ([delegate respondsToSelector:@selector(twitterAuthFailed:)]) {
//					[delegate twitterAuthFailed:self];
//				}
			});
		}
	});
}

- (void)getAcessTokenForRequestToken:(NSString *)requestToken andRequestTokenSecret:(NSString *)requestTokenSecret {
	
	dispatch_async(twitterQueue, ^{
		// Make the URL
		NSString *theURLString = @"https://api.twitter.com/oauth/access_token";	
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
		[request setTimeoutInterval:20];
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
//					if ([delegate respondsToSelector:@selector(twitterAuthFailed:)]) {
//						[delegate twitterAuthFailed:self];
//					}
				});
			} else {
				// Get the request token data
				// Parse the returned data
				
				NSArray *parameters = [jsonData componentsSeparatedByString:@"&"];
				NSMutableDictionary *accessTokenData = [NSMutableDictionary new];
				NSArray *temp;
				for (NSString *parameter in parameters) {
					temp = [parameter componentsSeparatedByString:@"="];
					[accessTokenData setObject:[temp objectAtIndex:1] forKey:[temp objectAtIndex:0]];
				}
				
				dispatch_async(dispatch_get_main_queue(), ^{
					// Build the acess token
					self.oauthToken = [[[OAToken alloc] initWithKey:[accessTokenData valueForKey:@"oauth_token"] secret:[accessTokenData valueForKey:@"oauth_token_secret"]] autorelease];
					// Request the display of a dialog
//					[delegate twitter:self authGotAcessToken:theToken forUser:[accessTokenData valueForKey:@"screen_name"]];
				});
				
				[accessTokenData release];
			}
			
		} else {
			// The NSURLConnection could not be made
			NSLog(@"%@: NSURLConnection error: %@", [self class], [error localizedDescription]);
			// Call the error function
			dispatch_async(dispatch_get_main_queue(), ^{
//				if ([delegate respondsToSelector:@selector(twitterAuthFailed:)]) {
//					[delegate twitterAuthFailed:self];
//				}
			});
		}
	});
}

#pragma mark - Request fetching

- (void)fetchJSONValueForRequest:(NSString *)requestString withArguments:(NSArray *)requestArguments requestType:(TwitterHTTPRequestType)requestType requestServer:(NSString *)requestServer completion:(void (^)(id result))completionBlock error:(void (^)(NSError *error))errorBlock {
	
	if (!self.oauthToken) {
		NSLog(@"Not authorized!");
	} else {
		dispatch_async(twitterQueue, ^{
			
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			// Connection type (HTTP or HTTPS)
			NSString *connectionType;
			connectionType = @"https";
			
			// Response format (JSON or XML). For now only JSON is supported!
			NSString *responseFormat = @"JSON";
			responseFormat = [NSString stringWithFormat:@".%@", [responseFormat lowercaseString]];
			
			// Make the URL
			NSString *theURLString = [NSString stringWithFormat:@"%@://%@%@%@", connectionType, requestServer, requestString, responseFormat];	
			
			// Log the URL to the console
			NSLog(@"%@", theURLString);
			
			// Cast the url in the NSURL object
			NSURL *url = [NSURL URLWithString:theURLString];
			
			// Initialize the request
			OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url consumer:[self oauthConsumer] token:[self oauthToken] realm:nil signatureProvider:[[OAHMAC_SHA1SignatureProvider alloc] init]] autorelease];
			
			// Set the HTTP method
			if (requestType == TwitterHTTPRequestTypePOST) {
				[request setHTTPMethod:@"POST"];
			}
			
			// Add the parameters
			[request setParameters:requestArguments];	
			
			// Set the request time out interval in seconds
			[request setTimeoutInterval:20];
			
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
					// Decode the JSON response
					resolvedResponse = [jsonData objectFromJSONString];
					// Debug
					NSLog(@"%@: Error:\nRequest: %@\nError description: %@", [self class], [resolvedResponse objectForKey:@"request"], [resolvedResponse objectForKey:@"error"]);
					// Prepare the error
					NSError *theError = [NSError errorWithDomain:@"com.jernejstrasner.twitter" code:100 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[resolvedResponse objectForKey:@"error"], NSLocalizedDescriptionKey, nil]];
					// Execute the error block
					dispatch_async(dispatch_get_main_queue(), ^{
						errorBlock(theError);
					});
				} else {
					// Resolve the response to an object
					// If there is an error on the server side it will get resolved to an NSMutableDictionary with "error" and "request" keys
					resolvedResponse = [jsonData objectFromJSONString];
					// Execute the completion block
					dispatch_async(dispatch_get_main_queue(), ^{
						completionBlock(resolvedResponse);
					});
				}
			} else {
				// The NSURLConnection could not be made
				NSLog(@"%@: NSURLConnection error: %@", [self class], [error localizedDescription]);
				// Execute the error block
				dispatch_async(dispatch_get_main_queue(), ^{
					errorBlock(error);
				});
			}
			
			[pool drain];
		});
	}
}

#pragma mark - Status methods

- (void)statusesUpdate:(NSString *)status completion:(void (^)(id result))completionBlock error:(void (^)(NSError *error))errorBlock {
    NSString *urlString = @"/statuses/update";
	
	NSArray *arguments = [NSArray arrayWithObjects:
						  [OARequestParameter requestParameterWithName:@"status" value:status],
						  nil];
	
	[self fetchJSONValueForRequest:urlString withArguments:arguments requestType:TwitterHTTPRequestTypePOST requestServer:kJSTwitterRestServerURL completion:completionBlock error:errorBlock];
}

@end
