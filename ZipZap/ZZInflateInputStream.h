//
//  ZZInflateInputStream.h
//  ZipZap
//
//  Created by Glen Low on 29/09/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZZInflateInputStream : NSInputStream

+ (NSData*)decompressData:(NSData*)data
	 withUncompressedSize:(NSUInteger)uncompressedSize;

- (instancetype)initWithStream:(NSInputStream*)upstream;

- (NSStreamStatus)streamStatus;
- (nullable NSError*)streamError;

- (void)open;
- (void)close;

- (NSInteger)read:(uint8_t*)buffer maxLength:(NSUInteger)len;
- (BOOL)getBuffer:(uint8_t* _Nullable* _Nonnull)buffer length:(NSUInteger*)len;
- (BOOL)hasBytesAvailable;

@end

NS_ASSUME_NONNULL_END
