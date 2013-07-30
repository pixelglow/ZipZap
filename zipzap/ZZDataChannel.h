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

- (instancetype)temporaryChannel:(NSError**)error;
- (BOOL)replaceWithChannel:(id<ZZChannel>)channel
					 error:(NSError**)error;
- (void)removeAsTemporary;

- (NSData*)openInput:(NSError**)error;
- (id<ZZChannelOutput>)openOutput:(NSError**)error;

@end
