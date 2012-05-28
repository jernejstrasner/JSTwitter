//
//  NSString+JSRandom.m
//  JSTwitter
//
//  Created by Jernej Strasner on 5/1/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import "NSString+JSRandom.h"

@implementation NSString (JSRandom)

+ (NSString *)randomStringOfLength:(NSUInteger)length
{
	// Character lookup table
    static const char alphanum[] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
	
	// Pick random characters and build a string
	char *string = calloc(length+1, sizeof(char));
	for (int i = 0; i < length; i++) {
		string[i] = alphanum[arc4random_uniform(sizeof(alphanum))];
	}
	
	// Add the C string delimiter
	string[length] = '\0';

	// Create an ObjC string
	NSString *result = [NSString stringWithCString:string encoding:NSASCIIStringEncoding];

	// Clean up
	free(string);

	return result;
}

@end
