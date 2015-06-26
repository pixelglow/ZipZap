//
//  ZZDataChannelTests.m
//  ZipZap
//
//  Created by Glen Low on 4/09/14.
//
//

#import <ZipZap/ZZDataChannel.h>

#import "ZZDataChannelTests.h"

@implementation ZZDataChannelTests
{
	NSData* _oldData;
	NSMutableData* _newData;
}

- (void)setUp
{
	[super setUp];

	_oldData = [@"hello, world" dataUsingEncoding:NSUTF8StringEncoding];
	_newData = [NSMutableData data];
}

- (void)tearDown
{
	_oldData = nil;
	_newData = nil;

	[super tearDown];
}

- (void)testInputForOldChannel
{
	[self checkInputForOldChannel:[[ZZDataChannel alloc] initWithData:_oldData]
					  toMatchData:_oldData];
}

- (void)testInputForNewChannel
{
	[self checkInputForNewChannel:[[ZZDataChannel alloc] initWithData:_newData]];
}

- (void)testOutputForNewChannel
{
	[self checkOutputForNewChannel:[[ZZDataChannel alloc] initWithData:_newData]];
}

- (void)testOutputStartOffset
{
	[self checkOutputStartOffsetForNewChannel:[[ZZDataChannel alloc] initWithData:_newData]];
}

- (void)testOutputWrite
{
	[self checkOutputWriteForNewChannel:[[ZZDataChannel alloc] initWithData:_newData]
								   data:_oldData];
}

- (void)testOutputSeek
{
	[self checkOutputSeekForNewChannel:[[ZZDataChannel alloc] initWithData:_newData]
								  data:_oldData
								offset:5];
}

- (void)testOutputTruncate
{
	[self checkOutputTruncateForNewChannel:[[ZZDataChannel alloc] initWithData:_newData]
									  data:_oldData
									offset:5];
}

@end
