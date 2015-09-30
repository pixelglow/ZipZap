//
//  ZZChannel.h
//  ZipZap
//
//  Created by Glen Low on 12/01/13.
//  Copyright (c) 2013, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZZChannelOutput;

NS_ASSUME_NONNULL_BEGIN

@protocol ZZChannel

@property (readonly, nullable, nonatomic) NSURL* URL;

- (nullable instancetype)temporaryChannel:(out NSError**)error;
- (BOOL)replaceWithChannel:(id<ZZChannel>)channel
					 error:(out NSError**)error;
- (void)removeAsTemporary;

- (nullable NSData*)newInput:(out NSError**)error;
- (nullable id<ZZChannelOutput>)newOutput:(out NSError**)error;

@end

NS_ASSUME_NONNULL_END
