//
//  ZZDataChannelOutput.h
//  zipzap
//
//  Created by Glen Low on 12/01/13.
//
//

#import <Foundation/Foundation.h>

#import "ZZChannelOutput.h"

@interface ZZDataChannelOutput : NSObject <ZZChannelOutput>

- (id)initWithData:(NSMutableData*)data
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
