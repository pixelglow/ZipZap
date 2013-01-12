//
//  ZZDataChannel.m
//  zipzap
//
//  Created by Glen Low on 12/01/13.
//
//

#import "ZZDataChannel.h"

@implementation ZZDataChannel
{
	NSData* _allData;
}

- (id)initWithData:(NSData*)data
{
	if ((self = [super init]))
		_allData = data;
	return self;
}

- (NSURL*)URL
{
	return nil;
}

- (NSData*)openInput
{
	return _allData;
}

- (id<ZZChannelOutput>)openOutput
{
	return nil;
}

@end
