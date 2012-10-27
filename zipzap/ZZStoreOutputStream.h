//
//  ZZStoreOutputStream.h
//  zipzap
//
//  Created by Glen Low on 13/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZZStoreOutputStream : NSOutputStream

@property (readonly, nonatomic) uint32_t crc32;
@property (readonly, nonatomic) uint32_t size;

- (id)initWithFileHandle:(NSFileHandle*)fileHandle;

- (void)open;
- (void)close;

- (NSInteger)write:(const uint8_t*)buffer maxLength:(NSUInteger)length;
- (BOOL)hasSpaceAvailable;

@end
