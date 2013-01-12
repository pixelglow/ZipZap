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

@property (nonatomic) uint32_t offset;

- (id)initWithData:(NSMutableData*)data;
- (void)write:(NSData*)data;
- (void)close;

@end
