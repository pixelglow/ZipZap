//
//  ZZDecryptInputStream.h
//  zipzap
//
//  Created by Daniel Cohen Gindi on 12/29/13.
//
//

#import <Foundation/Foundation.h>
#include "ZZDecrypter.h"

@interface ZZDecryptInputStream : NSInputStream

- (id)initWithStream:(NSInputStream*)upstream decrypter:(id<ZZDecrypter>)decrypter;

- (void)open;
- (void)close;

- (NSInteger)read:(uint8_t*)buffer maxLength:(NSUInteger)len;
- (BOOL)getBuffer:(uint8_t**)buffer length:(NSUInteger*)len;
- (BOOL)hasBytesAvailable;

@end
