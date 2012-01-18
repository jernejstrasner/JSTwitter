//
//  JSFacebook-NSDictionary.m
//  FacebookAPI
//
//  Created by Jernej Strasner on 3/31/11.
//  Copyright 2011 JernejStrasner.com. All rights reserved.
//

#import "JSTwitter-NSDictionary.h"

@implementation NSDictionary (JSTwitter)

- (NSString *)generateGETParameters {
	NSMutableArray *pairs = [NSMutableArray new];
	for (NSString *key in self) {
		// Get the object
		id obj = [self valueForKey:key];
		// Encode arrays and dictionaries in JSON
		if ([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]]) {
			obj = [obj JSONString];
		}
		// Escaping
		NSString *escaped_value = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, /* allocator */
																					  (CFStringRef)obj,
																					  NULL, /* charactersToLeaveUnescaped */
																					  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
																					  kCFStringEncodingUTF8);
		// Generate http request parameter pairs
		[pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
		[escaped_value release];
	}
	
	NSString *parameters = [pairs componentsJoinedByString:@"&"];
	[pairs release];
	
	return parameters;
}

- (NSData *)generatePOSTBodyWithBoundary:(NSString *)boundary {
	NSMutableData *body = [NSMutableData data];
	NSString *beginLine = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
	
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	for (id key in self) {
		id value = [self valueForKey:key];
		if ([value isKindOfClass:[UIImage class]]) {
			UIImage *image = [self objectForKey:key];
			NSData *data = UIImageJPEGRepresentation(image, 0.8);
			[body appendData:[beginLine dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[[NSString stringWithFormat:@"Content-Disposition: multipart/form-data; name=\"%@\"; filename=\"image.jpg\"\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[[NSString stringWithFormat:@"Content-Length: %d\r\n", [data length]] dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[[NSString stringWithString:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:data];
		} else if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
			[body appendData:[beginLine dataUsingEncoding:NSUTF8StringEncoding]];        
			[body appendData:[[NSString stringWithFormat:@"Content-Disposition: multipart/form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[value JSONData]];
		} else {
			[body appendData:[beginLine dataUsingEncoding:NSUTF8StringEncoding]];        
			[body appendData:[[NSString stringWithFormat:@"Content-Disposition: multipart/form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[value dataUsingEncoding:NSUTF8StringEncoding]];
		}
	}

	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	return body;
}

@end