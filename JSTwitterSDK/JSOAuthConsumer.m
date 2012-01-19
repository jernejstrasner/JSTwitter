//
//  JSOAuthConsumer.m
//  JSTwitter
//
//  Created by Jernej Strasner on 1/19/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import "JSOAuthConsumer.h"

@implementation JSOAuthConsumer

#pragma mark - Properties

@synthesize key = _key;
@synthesize secret = _secret;

#pragma mark - Lifecycle

- (id)initWithKey:(NSString *)key secret:(NSString *)secret
{
    self = [super init];
    if (self) {
        self.key = key;
        self.secret = secret;
    }
    return self;
}

- (void)dealloc
{
    [_key release];
    [_secret release];
    [super dealloc];
}

@end
