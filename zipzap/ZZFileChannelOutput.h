//
//  ZZFileChannelOutput.h
//  zipzap
//
//  Created by Glen Low on 12/01/13.
//
//

#import <Foundation/Foundation.h>

#import "ZZChannelOutput.h"

@interface ZZFileChannelOutput : NSObject <ZZChannelOutput>

@property (nonatomic) uint32_t offset;

- (id)initWithFileDescriptor:(int)fileDescriptor
				  offsetBias:(uint32_t)offsetBias;

- (uint32_t)offset;
- (BOOL)seekToOffset:(uint32_t)offset
			   error:(NSError**)error;

- (BOOL)writeData:(NSData*)data
			error:(NSError**)error;
- (BOOL)truncateAtOffset:(uint32_t)offset
				   error:(NSError**)error;

- (void)close;

@end
