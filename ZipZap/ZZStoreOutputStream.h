//
//  ZZStoreOutputStream.h
//  ZipZap
//
//  Created by Glen Low on 13/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZZChannelOutput;

NS_ASSUME_NONNULL_BEGIN

@interface ZZStoreOutputStream : NSOutputStream

@property (readonly, nonatomic) uint32_t crc32;
@property (readonly, nonatomic) uint32_t size;

- (instancetype)initWithChannelOutput:(id<ZZChannelOutput>)channelOutput;

- (NSStreamStatus)streamStatus;
- (nullable NSError*)streamError;

- (void)open;
- (void)close;

- (NSInteger)write:(const uint8_t*)buffer maxLength:(NSUInteger)length;
- (BOOL)hasSpaceAvailable;

@end

NS_ASSUME_NONNULL_END
