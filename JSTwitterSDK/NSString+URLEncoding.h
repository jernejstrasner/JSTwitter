//
//  NSString+URLEncoding.h
//  JSTwitter
//
//  Created by Jernej Strasner on 1/19/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (JSURLEncoding)

- (NSString *)URLEncodedString;
- (NSString *)URLDecodedString;

@end
