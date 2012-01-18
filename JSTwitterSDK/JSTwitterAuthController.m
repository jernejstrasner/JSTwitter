//
//  JSTwitterAuthDialog.m
//  KinoSporedi
//
//  Created by Jernej Strasner on 7/29/10.
//  Copyright 2010 JernejStrasner.com. All rights reserved.
//

#import "JSTwitterAuthController.h"
#import "JSTwitter.h"

@interface JSTwitterAuthController ()

@property (nonatomic, retain) UIWebView *webView;

// 1. stage
@property (nonatomic, retain) NSString *consumerKey;
@property (nonatomic, retain) NSString *consumerSecret;
// 2. stage
@property (nonatomic, retain) NSString *requestToken;
@property (nonatomic, retain) NSString *requestTokenSecret;

- (void)close;

@end

@implementation JSTwitterAuthController

#pragma mark - Properties

@synthesize webView = _webView;

@synthesize consumerKey = _consumerKey;
@synthesize consumerSecret = _consumerSecret;

@synthesize requestToken = _requestToken;
@synthesize requestTokenSecret = _requestTokenSecret;

@synthesize completionHandler;
@synthesize errorHandler;

#pragma mark - Lifecycle

- (id)initWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret
{
    self = [self init];
	if (self) {
		_consumerKey = [consumerKey retain];
		_consumerSecret = [consumerSecret retain];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
	// Web view
    self.webView = [[[UIWebView alloc] initWithFrame:self.view.bounds] autorelease];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];
    
    // Get the request token
    [[JSTwitter sharedInstance] getRequestTokenWithCompletionHandler:^(NSString *token, NSString *tokenSecret) {
        self.requestToken = token;
        self.requestTokenSecret = tokenSecret;
        // Load the auth page
        NSString *url = [kJSTwitterOauthServerURL stringByAppendingFormat:@"authorize?oauth_token=%@&oauth_callback=%@", self.requestToken, kJSTwitterOauthCallbackURL];
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];        
    } errorHandler:^(NSError *error) {
        NSLog(@"Error getting the request token!");
    }];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.webView = nil;
}

- (void)dealloc {
	[_webView stopLoading];
	_webView.delegate = nil;
	
    [_consumerKey release];
    [_consumerSecret release];
	[_requestToken release];
	[_requestTokenSecret release];
    
    [completionHandler release];
    [errorHandler release];
	
    [super dealloc];
}

#pragma mark - Initialization helpers

+ (JSTwitterAuthController *)authControllerWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret
{
    return [[[JSTwitterAuthController alloc] initWithConsumerKey:consumerKey consumerSecret:consumerSecret] autorelease];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	
	if ([[[request URL] absoluteString] hasPrefix:kJSTwitterOauthCallbackURL])
    {
        NSLog(@"Getting the access token...");
        [[JSTwitter sharedInstance] getAcessTokenForRequestToken:self.requestToken
                                              requestTokenSecret:self.requestTokenSecret
                                               completionHandler:^{
                                                   [self close];
                                                   self.completionHandler();
                                               }
                                                    errorHandler:^(NSError *error){
                                                        [self close];
                                                        self.errorHandler(error);
                                                    }];
		return NO;
	}
	return YES;
}

#pragma mark - Methods

- (void)close
{
    if ([self respondsToSelector:@selector(presentingViewController)]) {
        [self.presentingViewController dismissModalViewControllerAnimated:YES];
    } else {
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}

@end
