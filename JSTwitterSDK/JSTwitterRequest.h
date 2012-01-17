//
//  JSTwitterRequest.h
//  JSTwitter
//
//  Created by Jernej Strasner on 1/17/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    JSTwitterRequestTypeGET,
    JSTwitterRequestTypePOST
} JSTwitterRequestType;

@interface JSTwitterRequest : NSObject

@property (nonatomic, readonly) NSString *endpoint;
@property (nonatomic, readonly) JSTwitterRequestType requestType;
@property (nonatomic, readonly) NSDictionary *parameters;

- (id)initWithRestEndpoint:(NSString *)endpoint;
- (id)initWithRestEndpoint:(NSString *)endpoint requestType:(JSTwitterRequestType)requestType;

+ (JSTwitterRequest *)requestWithRestEndpoint:(NSString *)endpoint;
+ (JSTwitterRequest *)requestWithRestEndpoint:(NSString *)endpoint requestType:(JSTwitterRequestType)requestType;

- (void)addParameter:(id)value withKey:(NSString *)key;
- (void)removeParameterWithKey:(NSString *)key;

@end
