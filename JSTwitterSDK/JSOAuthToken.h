//
//  JSOAuthToken.h
//  JSTwitter
//
//  Created by Jernej Strasner on 1/19/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSOAuthToken : NSObject <NSCoding>

@property (nonatomic, retain) NSString *key;
@property (nonatomic, retain) NSString *secret;

- (id)initWithKey:(NSString *)key secret:(NSString *)secret;
- (id)initFromStorageWithKey:(NSString *)key;

- (void)storeWithKey:(NSString *)key;

@end
