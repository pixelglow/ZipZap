//
//  ZZAESDecryptInputStream.h
//  ZipZap
//
//  Created by Daniel Cohen Gindi on 6/1/14.
//  Copyright (c) 2014, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZZConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZAESDecryptInputStream : NSInputStream

- (nullable instancetype)initWithStream:(NSInputStream*)upstream
							   password:(NSString*)password
								 header:(uint8_t*)header
							   strength:(ZZAESEncryptionStrength)strength
								  error:(out NSError**)error;

- (void)open;
- (void)close;

- (NSStreamStatus)streamStatus;
- (NSError*)streamError;

- (NSInteger)read:(uint8_t*)buffer maxLength:(NSUInteger)len;
- (BOOL)getBuffer:(uint8_t* _Nullable* _Nonnull)buffer length:(NSUInteger*)len;
- (BOOL)hasBytesAvailable;

- (void)dealloc;

@end

NS_ASSUME_NONNULL_END
