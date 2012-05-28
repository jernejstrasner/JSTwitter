//
//  JSAppDelegate.m
//  JSTwitter
//
//  Created by Jernej Strasner on 1/17/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import "JSAppDelegate.h"

#import "JSViewController.h"

#import "JSTwitter.h"

@implementation JSAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[[JSViewController alloc] initWithNibName:@"JSViewController_iPhone" bundle:nil] autorelease];
    } else {
        self.viewController = [[[JSViewController alloc] initWithNibName:@"JSViewController_iPad" bundle:nil] autorelease];
    }
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    NSLog(@"Loading Twitter...");
    
    [[JSTwitter sharedInstance] setOauthConsumerKey:@""];
    [[JSTwitter sharedInstance] setOauthConsumerSecret:@""];
    
    [[JSTwitter sharedInstance] authenticateWithCompletionHandler:^{
        NSLog(@"Authenticated: [%@]%@", [[JSTwitter sharedInstance] userID], [[JSTwitter sharedInstance] username]);
        NSLog(@"Getting test data...");
//        JSTwitterRequest *request = [JSTwitterRequest requestWithRestEndpoint:@"/statuses/home_timeline"];
//        [[JSTwitter sharedInstance] fetchRequest:request onSuccess:^(id obj) {
//            NSLog(@"Got mentions: %@", obj);
//			
//			
//        } onError:^(NSError *error) {
//            NSLog(@"Error fetching mentions: %@", [error localizedDescription]);
//        }];
		JSTwitterRequest *req = [JSTwitterRequest requestWithRestEndpoint:@"/statuses/update_with_media" requestType:JSTwitterRequestTypePOST];
		[req addParameter:@"Testing JSTwitter" withKey:@"status"];
		[req addParameter:[UIImage imageNamed:@"IMG_0050.JPG"] withKey:@"media"];
		[[JSTwitter sharedInstance] fetchRequest:req onSuccess:^(id obj) {
			NSLog(@"Successfully posted!");
		} onError:^(NSError *error) {
			NSLog(@"ERROR: %@", error);
		}];

    } errorHandler:^(NSError *error) {
        NSLog(@"Authentication error!");
        [[JSTwitter sharedInstance] clearSession];
    }];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
