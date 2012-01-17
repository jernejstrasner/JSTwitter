//
//  JSTwitterAuthDialog.h
//  KinoSporedi
//
//  Created by Jernej Strasner on 7/29/10.
//  Copyright 2010 JernejStrasner.com. All rights reserved.
//

#import <UIKit/UIKit.h>


#define TWITTER_AUTHORIZE_URL @"https://api.twitter.com/oauth/authorize"
#define TWITTER_AUTHORIZE_CALLBACK @"http://jernejstrasner.com/twitter_callback/"

@protocol JSTwitterAuthDialogDelegate;

@interface JSTwitterAuthDialog : UIViewController <UIWebViewDelegate> {
	id <JSTwitterAuthDialogDelegate> delegate;
	
	UINavigationBar *navigationBar;
	UIWebView *webView;
	
	UIActivityIndicatorView *activityIndicator;
	
	NSString *_requestToken;
	NSString *_requestTokenSecret;
	
	UIColor *dialogTint;
}

@property (nonatomic, assign) id <JSTwitterAuthDialogDelegate> delegate;

@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) IBOutlet UIWebView *webView;

@property (nonatomic, retain) UIColor *dialogTint;

- (id)initWithRequestToken:(NSString *)requestToken requestTokenSecret:(NSString *)requestTokenSecret;

- (void)showLogin;
- (IBAction)cancel;

@end


@protocol JSTwitterAuthDialogDelegate <NSObject>

/**
 This is called when the user presses the cancel button
 */
- (void)twitterAuthDialogDidCancel:(JSTwitterAuthDialog *)authDialog;

/**
 Called when the permissions to the user are successfully granted
 */
- (void)twitterAuthDialog:(JSTwitterAuthDialog *)authDialog authorizedRequestToken:(NSString *)requestToken requestTokenSecret:(NSString *)requestTokenSecret;

@end