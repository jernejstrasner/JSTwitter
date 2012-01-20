//
//  JSTwitter.h
//  KinoSporedi
//
//  Created by Jernej Strasner on 7/28/10.
//  Copyright 2010 JernejStrasner.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>

#import "JSTwitterRequest.h"
#import "JSTwitterAuthController.h"


// Macros
#define JSTWLog(format, ...) NSLog((@"[Line %d] " format), __LINE__, ##__VA_ARGS__);

// Constants
extern NSString * const kJSTwitterRestServerURL;
extern NSString * const kJSTwitterOauthServerURL;
extern NSString * const kJSTwitterSearchServerURL;
extern NSString * const kJSTwitterOauthCallbackURL;
extern NSString * const kJSTwitterStringBoundary;
extern NSString * const kJSTwitterAccessTokenDefaultsKey;
extern NSString * const kJSTwitterNetworkErrorDomain;
extern NSString * const kJSTwitterOtherErrorDomain;

// Block types
typedef void(^jstwitter_success_block_t)(void);
typedef void(^jstwitter_success_data_block_t)(id obj);
typedef void(^jstwitter_error_block_t)(NSError *error);
typedef void(^jstwitter_request_token_success_block_t)(NSString *token, NSString *tokenSecret);


@interface JSTwitter : NSObject

// Properties
@property (nonatomic, retain) NSString *oauthConsumerKey;
@property (nonatomic, retain) NSString *oauthConsumerSecret;
@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) NSString *userID;

/**
 
 Singleton
 
 As soon as you access the singleton for the first time, you should set the consumer key
 and consumer secret, which you get from Twitter's developer website once you set up an app.
 */
+ (JSTwitter *)sharedInstance;


/**
 
 Authentication
 
 This is the method you should use for authentication. It opens a modal window in the
 app's root view controller with a web view. It does all the required oauth token exchanges for you.
 */
- (void)authenticateWithCompletionHandler:(jstwitter_auth_success_block_t)completionHandler
                             errorHandler:(jstwitter_auth_error_block_t)errorHandler;


/**
 
 OAuth token exchange
 
 You can use the methods below to more precisely control the authentication flow.
 It is suggested to use authenticateWithCompletionHandler:errorHandler: instead.
 */
- (void)getRequestTokenWithCompletionHandler:(jstwitter_request_token_success_block_t)completionHandler
                                errorHandler:(jstwitter_error_block_t)errorHandler;

- (void)getAcessTokenForRequestToken:(NSString *)requestToken
                  requestTokenSecret:(NSString *)requestTokenSecret
                   completionHandler:(jstwitter_success_block_t)completionHandler
                        errorHandler:(jstwitter_error_block_t)errorHandler;


/**
 
 Request fetching
 
 This methods is used to fetch data for a JSTwitterRequest object.
 */
- (void)fetchRequest:(JSTwitterRequest *)request
           onSuccess:(jstwitter_success_data_block_t)completionHandler
             onError:(jstwitter_error_block_t)errorHandler;

@end
