//
//  ZZDecrypter.h
//  zipzap
//
//  Created by Daniel Cohen Gindi on 12/29/13.
//
//

@protocol ZZDecrypter

- (void)decrypt:(uint8_t*)buffer length:(NSUInteger)len;

@end
