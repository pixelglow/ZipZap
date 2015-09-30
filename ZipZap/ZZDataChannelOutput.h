//
//  ZZDataChannelOutput.h
//  ZipZap
//
//  Created by Glen Low on 12/01/13.
//  Copyright (c) 2013, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZZChannelOutput.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZDataChannelOutput : NSObject <ZZChannelOutput>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithData:(NSMutableData*)data NS_DESIGNATED_INITIALIZER;

- (uint32_t)offset;
- (BOOL)seekToOffset:(uint32_t)offset
			   error:(out NSError**)error;

- (BOOL)writeData:(NSData*)data
			error:(out NSError**)error;
- (BOOL)truncateAtOffset:(uint32_t)offset
				   error:(out NSError**)error;
- (void)close;

@end

NS_ASSUME_NONNULL_END
