//
//  ZZDataChannel.m
//  zipzap
//
//  Created by Glen Low on 12/01/13.
//
//

#import "ZZDataChannel.h"
#import "ZZDataChannelOutput.h"

@implementation ZZDataChannel
{
	NSData* _allData;
}

- (id)initWithData:(NSData*)data
{
    NSParameterAssert(data);
	if ((self = [super init]))
		_allData = data;
	return self;
}

- (NSURL*)URL
{
	return nil;
}

- (id<ZZChannel>)temporaryChannel
{
	return [[ZZDataChannel alloc] initWithData:[NSMutableData data]];
}

- (BOOL)replaceWithChannel:(id<ZZChannel>)channel
{
	[(NSMutableData*)_allData setData:((ZZDataChannel*)channel)->_allData];
	return YES;
}

- (void)removeTemporaries
{
}

- (NSData*)openInput:(NSError *__autoreleasing *)error;
{
	return _allData;
}

- (id<ZZChannelOutput>)openOutputWithOffsetBias:(uint32_t)offsetBias
{
	return [[ZZDataChannelOutput alloc] initWithData:(NSMutableData*)_allData
										 offsetBias:offsetBias];
}

@end
