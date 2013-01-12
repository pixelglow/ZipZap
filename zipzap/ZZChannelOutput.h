//
//  ZZChannelOutput.h
//  zipzap
//
//  Created by Glen Low on 12/01/13.
//
//

#import <Foundation/Foundation.h>

@protocol ZZChannelOutput

@property (nonatomic) uint32_t offset;

- (void)write:(NSData*)data;
- (void)close;

@end
