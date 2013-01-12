//
//  ZZChannel.h
//  zipzap
//
//  Created by Glen Low on 12/01/13.
//
//

#import <Foundation/Foundation.h>

@protocol ZZChannelOutput;

@protocol ZZChannel

@property (readonly, nonatomic) NSURL* URL;

- (NSData*)openInput;
- (id<ZZChannelOutput>)openOutput;

@end
