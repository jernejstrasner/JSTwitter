//
//  NSString+JSOAuthSigning.m
//  JSTwitter
//
//  Created by Jernej Strasner on 1/19/12.
//  Copyright (c) 2012 JernejStrasner.com. All rights reserved.
//

#import "NSString+JSOAuthSigning.h"

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#import "Base64Transcoder.h"

@implementation NSString (JSOAuthSigning)

- (NSString *)HMACSHA1SignatureWithSecret:(NSString *)secret
{
    NSData *stringData = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, [secretData bytes], [secretData length], [stringData bytes], [stringData length], result);
    
    char base64_result[32];
    size_t base64_result_length = 32;
    
    Base64EncodeData(result, CC_SHA1_DIGEST_LENGTH, base64_result, &base64_result_length);
    
    return [[[NSString alloc] initWithData:[NSData dataWithBytes:base64_result length:base64_result_length] encoding:NSUTF8StringEncoding] autorelease];
}

@end
