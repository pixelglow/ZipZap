//
//  ZZChannelOutput.h
//  zipzap
//
//  Created by Glen Low on 12/01/13.
//
//

#import <Foundation/Foundation.h>

@protocol ZZChannelOutput

- (uint32_t)offset;
- (BOOL)seekToOffset:(uint32_t)offset
			   error:(NSError**)error;

- (BOOL)writeData:(NSData*)data
			error:(NSError**)error;
- (BOOL)truncateAtOffset:(uint32_t)offset
				   error:(NSError**)error;
- (void)close;

@end
