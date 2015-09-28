//
//  ZZFileChannel.h
//  ZipZap
//
//  Created by Glen Low on 12/01/13.
//
//

#import <Foundation/Foundation.h>

#import "ZZChannel.h"

@interface ZZFileChannel : NSObject <ZZChannel>

@property (readonly, nonatomic) NSURL* URL;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL*)URL NS_DESIGNATED_INITIALIZER;

- (instancetype)temporaryChannel:(out NSError**)error;
- (BOOL)replaceWithChannel:(id<ZZChannel>)channel
					 error:(out NSError**)error;
- (void)removeAsTemporary;

- (NSData*)newInput:(out NSError**)error;
- (id<ZZChannelOutput>)newOutput:(out NSError**)error;

@end
