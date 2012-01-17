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
#import "JSTwitterAuthDialog.h"


extern NSString * const kJSTwitterRestServerURL;
extern NSString * const kJSTwitterOauthServerURL;
extern NSString * const kJSTwitterSearchServerURL;


// Block types
typedef void(^jstwitter_success_block_t)(void);
typedef void(^jstwitter_error_block_t)(NSError *error);
typedef void(^jstwitter_request_token_success_block_t)(NSString *token, NSString *tokenSecret);
typedef void(^jstwitter_access_token_success_block_t)(OAToken *token, NSString *user);


@interface JSTwitter : NSObject

// Properties
@property (nonatomic, retain) NSString *oauthConsumerKey;
@property (nonatomic, retain) NSString *oauthConsumerSecret;

// Singleton
+ (JSTwitter *)sharedInstance;

// OAuth
- (void)getRequestTokenWithCompletionHandler:(jstwitter_request_token_success_block_t)completionHandler
                                errorHandler:(jstwitter_error_block_t)errorHandler;

- (void)getAcessTokenForRequestToken:(NSString *)requestToken
                  requestTokenSecret:(NSString *)requestTokenSecret
                   completionHandler:(jstwitter_access_token_success_block_t)completionHandler
                        errorHandler:(jstwitter_error_block_t)errorHandler;

- (BOOL)resumeSessionForUser:(NSString *)user;
- (BOOL)saveSessionForUser:(NSString *)user;

//// Request building
//- (void)fetchJSONValueForRequest:(NSString *)requestString withArguments:(NSArray *)requestArguments requestType:(JSTwitterRequestType)requestType requestServer:(NSString *)requestServer completion:(void (^)(id result))completionBlock error:(void (^)(NSError *error))errorBlock;
//
//// Status updating
//- (void)statusesUpdate:(NSString *)status completion:(void (^)(id result))completionBlock error:(void (^)(NSError *error))errorBlock;

@end

//@protocol JSTwitterDelegate <NSObject>
//
//@required
//- (void)twitterAuthFailed:(JSTwitter *)twitter;
//- (void)twitter:(JSTwitter *)twitter authGotRequestToken:(NSString *)token secret:(NSString *)secret;
//- (void)twitter:(JSTwitter *)twitter authGotAcessToken:(OAToken *)token forUser:(NSString *)user;
//
//@end
//
