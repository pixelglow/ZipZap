//
//  ZZDataChannel.h
//  zipzap
//
//  Created by Glen Low on 12/01/13.
//
//

#import <Foundation/Foundation.h>

#import "ZZChannel.h"

@interface ZZDataChannel : NSObject <ZZChannel>

@property (readonly, nonatomic) NSURL* URL;

- (id)initWithData:(NSData*)data;

- (id<ZZChannel>)temporaryChannel;
- (BOOL)replaceWithChannel:(id<ZZChannel>)channel;
- (void)removeTemporaries;

- (NSData*)openInput;
- (id<ZZChannelOutput>)openOutputWithOffsetBias:(uint32_t)offsetBias;

@end
