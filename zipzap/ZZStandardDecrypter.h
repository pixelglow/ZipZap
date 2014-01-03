//
//  ZZStandardDecrypter.h
//  zipzap
//
//  Created by Daniel Cohen Gindi on 12/29/13.
//
//

#import "ZZDecrypter.h"

@interface ZZStandardDecrypter : NSObject <ZZDecrypter>

- (id)initWithPassword:(NSString*)password header:(uint8_t*)header;

- (void)decrypt:(uint8_t*)buffer length:(NSUInteger)len;

@end