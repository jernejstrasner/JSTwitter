//
//  JSTwitter.h
//  KinoSporedi
//
//  Created by Jernej Strasner on 7/28/10.
//  Copyright 2010 JernejStrasner.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>
#import "OAuthConsumer.h"

#import "JSTwitterRequest.h"
#import "JSTwitterAuthController.h"


extern NSString * const kJSTwitterRestServerURL;
extern NSString * const kJSTwitterOauthServerURL;
extern NSString * const kJSTwitterSearchServerURL;
extern NSString * const kJSTwitterOauthCallbackURL;


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

// Singleton
+ (JSTwitter *)sharedInstance;

// Authentication
- (void)authenticateWithCompletionHandler:(jstwitter_auth_success_block_t)completionHandler
                             errorHandler:(jstwitter_auth_error_block_t)errorHandler;

// OAuth (internal use)
- (void)getRequestTokenWithCompletionHandler:(jstwitter_request_token_success_block_t)completionHandler
                                errorHandler:(jstwitter_error_block_t)errorHandler;

- (void)getAcessTokenForRequestToken:(NSString *)requestToken
                  requestTokenSecret:(NSString *)requestTokenSecret
                   completionHandler:(jstwitter_success_block_t)completionHandler
                        errorHandler:(jstwitter_error_block_t)errorHandler;


// Requests
- (void)fetchRequest:(JSTwitterRequest *)request
           onSuccess:(jstwitter_success_data_block_t)completionHandler
             onError:(jstwitter_error_block_t)errorHandler;

@end
