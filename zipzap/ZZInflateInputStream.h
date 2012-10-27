//
//  ZZInflateInputStream.h
//  zipzap
//
//  Created by Glen Low on 29/09/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZZInflateInputStream : NSInputStream

- (id)initWithData:(NSData*)data;

- (void)open;
- (void)close;

- (NSInteger)read:(uint8_t*)buffer maxLength:(NSUInteger)len;
- (BOOL)getBuffer:(uint8_t**)buffer length:(NSUInteger*)len;
- (BOOL)hasBytesAvailable;

- (void)rewind;
- (off_t)skipForward:(off_t)count;

@end
