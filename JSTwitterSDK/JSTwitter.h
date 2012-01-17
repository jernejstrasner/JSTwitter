//
//  JSTwitter.h
//  KinoSporedi
//
//  Created by Jernej Strasner on 7/28/10.
//  Copyright 2010 JernejStrasner.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>

#import "JSTwitterAuthDialog.h"
#import "OAuthConsumer.h"


#define TWITTER_SERVER @"twitter.com"
#define TWITTER_API_SERVER @"api.twitter.com"
#define TWITTER_API_VERSION 1
#define TWITTER_SEARCH_SERVER @"search.twitter.com"


// KinoSporedi
#define OAUTH_CONSUMER_KEY @"kj3n9A8oOX6wj0o3KeLyWw"
#define OAUTH_CONSUMER_SECRET @"HB4cF7Vv4j5O2FU2CMlxkN9rsW4TXtTm7m9UPEjxjAM"

// Request types
typedef enum {
	TwitterHTTPRequestTypePOST,
	TwitterHTTPRequestTypeGET,
	TwitterHTTPRequestTypeDELETE
} TwitterHTTPRequestType;

// Block types
typedef void(^jstwitter_success_block_t)(void);
typedef void(^jstwitter_error_block_t)(NSError *error);


@interface JSTwitter : NSObject

// OAuth
- (void)getRequestToken;
- (void)getAcessTokenForRequestToken:(NSString *)requestToken andRequestTokenSecret:(NSString *)requestTokenSecret;
- (BOOL)resumeSessionForUser:(NSString *)user;
- (BOOL)saveSessionForUser:(NSString *)user;

// Request building
- (void)fetchJSONValueForRequest:(NSString *)requestString withArguments:(NSArray *)requestArguments requestType:(TwitterHTTPRequestType)requestType requestServer:(NSString *)requestServer completion:(void (^)(id result))completionBlock error:(void (^)(NSError *error))errorBlock;

// Status updating
- (void)statusesUpdate:(NSString *)status completion:(void (^)(id result))completionBlock error:(void (^)(NSError *error))errorBlock;

@end

@protocol JSTwitterDelegate <NSObject>

@required
- (void)twitterAuthFailed:(JSTwitter *)twitter;
- (void)twitter:(JSTwitter *)twitter authGotRequestToken:(NSString *)token secret:(NSString *)secret;
- (void)twitter:(JSTwitter *)twitter authGotAcessToken:(OAToken *)token forUser:(NSString *)user;

@end

