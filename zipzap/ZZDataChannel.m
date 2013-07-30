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
	if ((self = [super init]))
		_allData = data;
	return self;
}

- (NSURL*)URL
{
	return nil;
}

- (instancetype)temporaryChannel:(NSError**)error
{
	return [[ZZDataChannel alloc] initWithData:[NSMutableData data]];
}

- (BOOL)replaceWithChannel:(id<ZZChannel>)channel
					 error:(NSError**)error
{
	[(NSMutableData*)_allData setData:((ZZDataChannel*)channel)->_allData];
	return YES;
}

- (void)removeAsTemporary
{
	_allData = nil;
}

- (NSData*)openInput:(NSError**)error
{
	return _allData;
}

- (id<ZZChannelOutput>)openOutput:(NSError**)error
{
	return [[ZZDataChannelOutput alloc] initWithData:(NSMutableData*)_allData];
}

@end
