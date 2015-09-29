//
//  ZZStandardDecryptInputStream.h
//  ZipZap
//
//  Created by Daniel Cohen Gindi on 29/12/13.
//  Copyright (c) 2013, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZZStandardDecryptInputStream : NSInputStream

- (instancetype)initWithStream:(NSInputStream*)upstream
					  password:(NSString*)password
						header:(uint8_t*)header
						 check:(uint16_t)check
					   version:(uint8_t)version
						 error:(out NSError**)error;

- (void)open;
- (void)close;

- (NSInteger)read:(uint8_t*)buffer maxLength:(NSUInteger)len;
- (BOOL)getBuffer:(uint8_t**)buffer length:(NSUInteger*)len;
- (BOOL)hasBytesAvailable;

@end
