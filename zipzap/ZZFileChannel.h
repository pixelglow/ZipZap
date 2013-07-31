//
//  ZZFileChannel.h
//  zipzap
//
//  Created by Glen Low on 12/01/13.
//
//

#import <Foundation/Foundation.h>

#import "ZZChannel.h"

@interface ZZFileChannel : NSObject <ZZChannel>

@property (readonly, nonatomic) NSURL* URL;

- (id)initWithURL:(NSURL*)URL;

- (instancetype)temporaryChannel:(NSError**)error;
- (BOOL)replaceWithChannel:(id<ZZChannel>)channel
					 error:(NSError**)error;
- (void)removeAsTemporary;

- (NSData*)newInput:(NSError**)error;
- (id<ZZChannelOutput>)newOutput:(NSError**)error;

@end
