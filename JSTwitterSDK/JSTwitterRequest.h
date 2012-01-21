//
//  JSTwitterRequest.h
//  JSTwitter
//
//  Created by Jernej Strasner on 1/17/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JSOAuthRequest.h"

typedef enum {
    JSTwitterRequestTypeGET,
    JSTwitterRequestTypePOST
} JSTwitterRequestType;

@interface JSTwitterRequest : JSOAuthRequest

@property (nonatomic, retain) NSString *endpoint;
@property (nonatomic, assign) JSTwitterRequestType requestType;
@property (nonatomic, retain) NSMutableDictionary *twitterParameters;

/**
 
 Initialization
 
 Use the methods below to create a twitter request object.
 */
- (id)initWithRestEndpoint:(NSString *)endpoint;
- (id)initWithRestEndpoint:(NSString *)endpoint requestType:(JSTwitterRequestType)requestType;

+ (JSTwitterRequest *)requestWithRestEndpoint:(NSString *)endpoint;
+ (JSTwitterRequest *)requestWithRestEndpoint:(NSString *)endpoint requestType:(JSTwitterRequestType)requestType;


/**
 
 Parameters
 
 */
- (void)addParameter:(id)value withKey:(NSString *)key;
- (void)removeParameterWithKey:(NSString *)key;

@end
