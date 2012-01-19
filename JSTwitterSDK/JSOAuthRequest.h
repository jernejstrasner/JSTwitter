//
//  JSOAuthRequest.h
//  JSTwitter
//
//  Created by Jernej Strasner on 1/19/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JSOAuthConsumer.h"
#import "JSOAuthToken.h"

@interface JSOAuthRequest : NSMutableURLRequest

@property (nonatomic, retain) JSOAuthConsumer *consumer;
@property (nonatomic, retain) JSOAuthToken *token;
@property (nonatomic, retain) NSMutableDictionary *oauthParameters;

- (id)initWithURL:(NSURL *)URL consumer:(JSOAuthConsumer *)consumer token:(JSOAuthToken *)token;

- (void)setOAuthParameterValue:(id)value forKey:(NSString *)key;

@end
