//
//  JSAppDelegate.h
//  JSTwitter
//
//  Created by Jernej Strasner on 1/17/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JSViewController;

@interface JSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) JSViewController *viewController;

@end
