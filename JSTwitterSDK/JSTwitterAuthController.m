//
//  JSTwitterAuthDialog.m
//  KinoSporedi
//
//  Created by Jernej Strasner on 7/29/10.
//  Copyright 2010 JernejStrasner.com. All rights reserved.
//

#import "JSTwitterAuthController.h"


@implementation JSTwitterAuthController

@synthesize delegate;
@synthesize navigationBar, webView;
@synthesize dialogTint;


- (id)initWithRequestToken:(NSString *)requestToken requestTokenSecret:(NSString *)requestTokenSecret {
	if (self = [self initWithNibName:@"JSTwitterAuthDialog" bundle:nil]) {
		_requestToken = [requestToken retain];
		_requestTokenSecret = [requestTokenSecret retain];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if (dialogTint) {
		navigationBar.tintColor = dialogTint;
	}
	
	// Add an activity indicator
	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[activityIndicator setHidesWhenStopped:YES];
	
	UIBarButtonItem *activityBarItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	navigationBar.topItem.leftBarButtonItem = activityBarItem;
	[activityBarItem release];
}

#pragma mark -
#pragma mark Methods

- (IBAction)cancel {
	if ([delegate respondsToSelector:@selector(twitterAuthDialogDidCancel:)]) {
		[delegate twitterAuthDialogDidCancel:self];
	}
}

#pragma mark -
#pragma mark Methods

- (void)showLogin {
	NSString *url = [NSString stringWithFormat:@"%@?oauth_token=%@&oauth_callback=%@", TWITTER_AUTHORIZE_URL, _requestToken, TWITTER_AUTHORIZE_CALLBACK];
	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
	
	// Display the loading overlay
	loadingOverlay = [[KSLoadingOverlay alloc] initInView:self.webView withMessage:@"Nalagam..."];
	[loadingOverlay show];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)aWebView {
	[activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
	if (loadingOverlay) {
		[loadingOverlay hide];
	}
	
	[activityIndicator stopAnimating];
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	
	if ([[[request URL] absoluteString] hasPrefix:TWITTER_AUTHORIZE_CALLBACK]) {

		if ([delegate respondsToSelector:@selector(twitterAuthDialog:authorizedRequestToken:requestTokenSecret:)]) {
			[delegate twitterAuthDialog:self authorizedRequestToken:_requestToken requestTokenSecret:_requestTokenSecret];
		}
		
		return NO;
	}
	
	return YES;
}

#pragma mark -
#pragma mark MemoryManagement

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.navigationBar = nil;
	self.webView = nil;
}


- (void)dealloc {
	[loadingOverlay release];
	
	[webView stopLoading];
	webView.delegate = nil;
	
	[_requestToken release];
	[_requestTokenSecret release];
	
	[activityIndicator release];
	
	[dialogTint release];
	
    [super dealloc];
}


@end
