//
//  ZZChannelTests.m
//  ZipZap
//
//  Created by Glen Low on 4/09/14.
//  Copyright (c) 2014, Pixelglow Software. All rights reserved.
//

#import <ZipZap/ZZChannel.h>
#import <ZipZap/ZZChannelOutput.h>

#import "ZZChannelTests.h"

@implementation ZZChannelTests

- (void)checkInputForOldChannel:(id<ZZChannel>)oldChannel toMatchData:(NSData*)matchData
{
	NSError* err;
	NSData* input = [oldChannel newInput:&err];

	XCTAssertNil(err, @"[channel newInput:...] should not error");
	XCTAssertEqualObjects(input, matchData, @"[channel newInput:...] must match original data");
}

- (void)checkInputForNewChannel:(id<ZZChannel>)newChannel
{
	NSError* err;
	NSData* input = [newChannel newInput:&err];

	XCTAssertNotNil(err, @"[channel newInput:...] should error");
	XCTAssertNil(input, @"[channel newInput:...] should not return anything");
}

- (void)checkOutputForNewChannel:(id<ZZChannel>)newChannel
{
	NSError* err;
	id<ZZChannelOutput> output = [newChannel newOutput:&err];

	XCTAssertNil(err, @"[channel newInput:...] should not error");
	XCTAssertNotNil(output, @"[channel newInput:...] should return something");

	[output close];
}

- (void)checkOutputStartOffsetForNewChannel:(id<ZZChannel>)newChannel
{
	NSError* err;
	id<ZZChannelOutput> output = [newChannel newOutput:&err];

	XCTAssertEqual(output.offset, 0, @"channelOutput.offset should be 0 at start");

	[output close];
}

- (void)checkOutputWriteForNewChannel:(id<ZZChannel>)newChannel data:(NSData*)data
{
	NSError* err;
	id<ZZChannelOutput> output = [newChannel newOutput:&err];

	err = nil;
	BOOL result = [output writeData:data error:&err];
	XCTAssertNil(err, "[channelOutput writeData:... error:...] should not error");
	XCTAssertTrue(result, "[channelOutput writeData:... error:...] should succeed");
	XCTAssertEqual(output.offset, data.length, "[channelOutput writeData:... error:...] should update offset");

	[output close];

	NSData* writtenData = [newChannel newInput:&err];
	XCTAssertEqualObjects(writtenData, data, "[channelOutput writeData:... error:...] written data should match original data");
}

- (void)checkOutputSeekForNewChannel:(id<ZZChannel>)newChannel data:(NSData*)data offset:(uint32_t)offset
{
	NSError* err;
	id<ZZChannelOutput> output = [newChannel newOutput:&err];
	[output writeData:data error:&err];

	err = nil;
	BOOL result = [output seekToOffset:offset error:&err];
	XCTAssertNil(err, @"[channelOutput seekToOffset:... error:...] should not error");
	XCTAssertTrue(result, @"[channelOutput seekToOffset:... error:...] should succeed");
	XCTAssertEqual(output.offset, offset, @"offset should update after seek");

	[output close];
}

- (void)checkOutputTruncateForNewChannel:(id<ZZChannel>)newChannel data:(NSData*)data offset:(uint32_t)offset
{
	NSError* err;
	id<ZZChannelOutput> output = [newChannel newOutput:&err];
	[output writeData:data error:&err];

	err = nil;
	BOOL result = [output truncateAtOffset:offset error:&err];
	XCTAssertNil(err, "[channelOutput truncateAtOffset:... error:...] should not error");
	XCTAssertTrue(result, "[channelOutput truncateAtOffset:... error:...] should succeed");

	[output close];

	NSData* writtenData = [newChannel newInput:&err];
	XCTAssertEqualObjects(writtenData,
						  [data subdataWithRange:NSMakeRange(0, offset)],
						  "[channelOutput truncateAtOffset:... error:...] data should match truncated original data");
}

@end
