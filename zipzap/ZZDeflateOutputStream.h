//
//  ZZDeflateOutputStream.h
//  zipzap
//
//  Created by Glen Low on 9/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZZDeflateOutputStream : NSOutputStream

@property (readonly, nonatomic) uint32_t crc32;
@property (readonly, nonatomic) uint32_t compressedSize;
@property (readonly, nonatomic) uint32_t uncompressedSize;

- (id)initWithFileHandle:(NSFileHandle*)fileHandle
		compressionLevel:(NSUInteger)compressionLevel;

- (void)open;
- (void)close;

- (NSInteger)write:(const uint8_t*)buffer maxLength:(NSUInteger)length;
- (BOOL)hasSpaceAvailable;

@end
