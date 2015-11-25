//
//  ZZStandardDecryptInputStream.h
//  ZipZap
//
//  Created by Daniel Cohen Gindi on 29/12/13.
//  Copyright (c) 2013, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZZStandardDecryptInputStream : NSInputStream

- (nullable instancetype)initWithStream:(NSInputStream*)upstream
							   password:(NSString*)password
								 header:(uint8_t*)header
								  check:(uint16_t)check
								version:(uint8_t)version
								  error:(out NSError**)error;

- (void)open;
- (void)close;

- (NSStreamStatus)streamStatus;
- (NSError*)streamError;

- (NSInteger)read:(uint8_t*)buffer maxLength:(NSUInteger)len;
- (BOOL)getBuffer:(uint8_t* _Nullable* _Nonnull)buffer length:(NSUInteger*)len;
- (BOOL)hasBytesAvailable;

@end

NS_ASSUME_NONNULL_END
