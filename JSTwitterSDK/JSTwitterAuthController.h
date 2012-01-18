//
//  JSTwitterAuthDialog.h
//  KinoSporedi
//
//  Created by Jernej Strasner on 7/29/10.
//  Copyright 2010 JernejStrasner.com. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void(^jstwitter_auth_error_block_t)(NSError *error);
typedef void(^jstwitter_auth_success_block_t)(void);


@interface JSTwitterAuthController : UIViewController <UIWebViewDelegate>

@property (nonatomic, retain) UINavigationBar *navigationBar;

/**
 
 Initialization
 
 */
- (id)initWithConsumerKey:(NSString *)consumerKey
           consumerSecret:(NSString *)consumerSecret;

+ (JSTwitterAuthController *)authControllerWithConsumerKey:(NSString *)consumerKey
                                            consumerSecret:(NSString *)consumerSecret;

/**
 
 Completion handlers
 
 */
@property (nonatomic, copy) jstwitter_auth_success_block_t completionHandler;
@property (nonatomic, copy) jstwitter_auth_error_block_t errorHandler;

@end
