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

- (NSData*)openInput;
- (id<ZZChannelOutput>)openOutput;

@end
