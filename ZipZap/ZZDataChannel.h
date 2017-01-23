//
//  ZZDataChannel.h
//  ZipZap
//
//  Created by Glen Low on 12/01/13.
//  Copyright (c) 2013, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZZChannel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZDataChannel : NSObject <ZZChannel>

@property (readonly, nullable, nonatomic) NSURL* URL;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithData:(NSData*)data NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)temporaryChannel:(out NSError**)error;
- (BOOL)replaceWithChannel:(id<ZZChannel>)channel
					 error:(out NSError**)error;
- (void)removeAsTemporary;

- (nullable NSData*)newInput:(out NSError**)error;
- (nullable id<ZZChannelOutput>)newOutput:(out NSError**)error;

@end

NS_ASSUME_NONNULL_END
