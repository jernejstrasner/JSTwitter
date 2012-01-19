//
//  NSURL+Base.m
//  JSTwitter
//
//  Created by Jernej Strasner on 1/19/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import "NSURL+Base.h"


@implementation NSURL (JSBase)

- (NSString *)URLStringWithoutQuery 
{
    NSString *urlString = [self absoluteString];
    NSRange range = [urlString rangeOfString:@"?"];
    if (range.location != NSNotFound) {
        return [urlString substringToIndex:range.location];
    }
    return urlString;
}

@end
